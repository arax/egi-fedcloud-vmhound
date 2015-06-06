require 'opennebula'

#
class Egi::Fedcloud::Vmhound::Connectors::OpennebulaConnector < Egi::Fedcloud::Vmhound::Connectors::BaseConnector

  # Number of VMs to process in one iteration
  VM_POOL_BATCH_SIZE = 10000

  # Initializes a connector instance.
  #
  # @param opts [Hash] options for the connector
  def initialize(opts = {})
    super
    # TODO: use configured credentials
    client = OpenNebula::Client.new

    @vm_pool = OpenNebula::VirtualMachinePool.new(client)
    @vm_pool_ary = nil

    @image_pool = OpenNebula::ImagePool.new(client)
    @canonical_image_pool = nil

    @user_pool = OpenNebula::UserPool.new(client)
    @canonical_user_pool = nil
  end

  # Retrieves all instances from the underlying OpenNebula. Including instances
  # already terminated by the user.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def all_instances
    instances
  end

  # Retrieves active instances from the underlying OpenNebula. Including instances
  # in transitional or suspended states. Terminated instances will not be
  # included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def active_instances
    instances nil, ['DONE', 'INIT']
  end

  # Retrieves running instances from the underlying OpenNebula. Only currently
  # running instances will be included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def running_instances
    instances ['ACTIVE']
  end

  private

  # Retrieves a list of instances matching given criteria.
  #
  # @param allow_states [Array<String>] a list of allowed states
  # @param reject_states [Array<String>] a list of states to be rejected
  # @return [Array<Hash>] a list of instances matching given criteria
  def instances(allow_states = nil, reject_states = nil)
    return if allow_states && allow_states.empty?
    reject_states ||= []

    @vm_pool_ary = instances_batch_pool(@vm_pool) unless @vm_pool_ary

    vms = []
    @vm_pool_ary.each do |vm|
      next if reject_states.include? vm.state_str
      vms << canonical_instance(vm) if (allow_states.nil? || (allow_states && allow_states.include?(vm.state_str)))
    end

    vms
  end

  # Hides batch processing from the rest of the application. Returns
  # a complete list of VM instances regardless of the underlying
  # batch size.
  #
  # @param vm_pool [OpenNebula::VirtualMachinePool] ONe pool instance
  # @return [Array<OpenNebula::VirtualMachine>] a list of VM instances
  def instances_batch_pool(vm_pool)
    fail 'Pool object not provided!' unless vm_pool

    batch_start = 0
    batch_stop = VM_POOL_BATCH_SIZE - 1
    vm_pool_ary = []

    begin
      check_retval vm_pool.info(
        OpenNebula::VirtualMachinePool::INFO_ALL,
        batch_start, batch_stop,
        OpenNebula::VirtualMachinePool::INFO_ALL_VM
      )
      vm_pool_ary.concat vm_pool.to_a unless vm_pool.count < 1

      batch_start = batch_stop + 1
      batch_stop += VM_POOL_BATCH_SIZE
    end until vm_pool.count < 1

    vm_pool_ary.compact!
    vm_pool_ary
  end

  # Retrieves a list of images.
  #
  # @return [Array<Hash>] a list of images
  def images
    return @canonical_image_pool if @canonical_image_pool
    check_retval @image_pool.info_all!

    @canonical_image_pool = []
    @image_pool.each { |image| @canonical_image_pool << canonical_image(image) }
    @canonical_image_pool
  end

  # Retrieves images by ID.
  #
  # @param image_id [String,Integer] native image ID
  # @return [Hash,NilClass] canonical image structure
  def image_by_id(image_id)
    images.select { |image| image[:id] == image_id.to_i }.first
  end

  # Retrieves a list of users.
  #
  # @return [Array<Hash>] a list of users
  def users
    return @canonical_user_pool if @canonical_user_pool
    check_retval @user_pool.info!

    @canonical_user_pool = []
    @user_pool.each { |user| @canonical_user_pool << canonical_user(user) }
    @canonical_user_pool
  end

  # Retrieves users by ID.
  #
  # @param user_id [String,Integer] native user ID
  # @return [Hash,NilClass] canonical user structure
  def user_by_id(user_id)
    users.select { |user| user[:id] == user_id.to_i }.first
  end

  # Creates a canonical instance representation in hash form.
  #
  # @param opennebula_instance [OpenNebula::VirtualMachine] ONe VM instance
  # @return [Hash] canonical VM representation in hash form
  def canonical_instance(opennebula_instance)
    fail 'Instance object not provided!' unless opennebula_instance
    {
      id: opennebula_instance['ID'].to_i,
      name: opennebula_instance['NAME'],
      owner: user_by_id(opennebula_instance['UID']),
      appliance: image_by_id(opennebula_instance['TEMPLATE/DISK[1]/IMAGE_ID']),
      ips: canonical_instance_ips(opennebula_instance),
      identifiers: canonical_instance_identifiers(opennebula_instance),
      host: canonical_instance_host(opennebula_instance),
      state: opennebula_instance.state_str,
    }
  end

  # Creates a canonical IP representation in array form.
  #
  # @param opennebula_instance [OpenNebula::VirtualMachine] ONe VM instance
  # @return [Array<String>] canonical IP representation in array form
  def canonical_instance_ips(opennebula_instance)
    fail 'Instance object not provided!' unless opennebula_instance
    ips = []

    opennebula_instance.each('TEMPLATE/NIC') { |nic| ips << nic['IP'] }
    ips.compact!

    ips
  end

  # Creates a canonical representation of instance identifiers in array form.
  #
  # @param opennebula_instance [OpenNebula::VirtualMachine] ONe VM instance
  # @return [Array<String>] canonical representation of instance identifiers in array form
  def canonical_instance_identifiers(opennebula_instance)
    fail 'Instance object not provided!' unless opennebula_instance
    identifiers = []

    identifiers << opennebula_instance['USER_TEMPLATE/OCCI_ID']
    identifiers << opennebula_instance['NAME']
    identifiers << opennebula_instance['ID'].to_s
    identifiers.compact!

    identifiers
  end

  # Creates a canonical representation of an instance host in string form.
  #
  # @param opennebula_instance [OpenNebula::VirtualMachine] ONe VM instance
  # @return [String] canonical representation of an instance host in string form
  def canonical_instance_host(opennebula_instance)
    fail 'Instance object not provided!' unless opennebula_instance
    hosts = []

    opennebula_instance.each('HISTORY_RECORDS/HISTORY') { |history| hosts << history['HOSTNAME'] }
    hosts.compact!

    hosts.last
  end

  # Creates a canonical image representation in hash form.
  #
  # @param opennebula_image [OpenNebula::Image] ONe image
  # @return [Hash] canonical image representation in hash form
  def canonical_image(opennebula_image)
    fail 'Image object not provided!' unless opennebula_image
    {
      id: opennebula_image['ID'].to_i,
      name: opennebula_image['NAME'],
      location: opennebula_image['SOURCE'],
      state: opennebula_image.state_str,
      datastore: opennebula_image['DATASTORE'],
      owner: {
        user: opennebula_image['UNAME'],
        group: opennebula_image['GNAME'],
      },
      identifiers: canonical_image_identifiers(opennebula_image),
    }
  end

  # Creates a canonical representation of image identifiers in array form.
  #
  # @param opennebula_image [OpenNebula::Image] ONe image
  # @return [Array<String>] canonical representation of identifiers in array form
  def canonical_image_identifiers(opennebula_image)
    fail 'Image object not provided!' unless opennebula_image
    identifiers = []

    identifiers << opennebula_image['TEMPLATE/VMCATCHER_EVENT_AD_MPURI']
    identifiers << opennebula_image['TEMPLATE/VMCATCHER_EVENT_DC_IDENTIFIER']
    identifiers << opennebula_image['NAME']
    identifiers << opennebula_image['ID'].to_s
    identifiers.compact!

    identifiers
  end

  # Creates a canonical user representation in hash form.
  #
  # @param opennebula_user [OpenNebula::User] ONe user
  # @return [Hash] canonical user representation in hash form
  def canonical_user(opennebula_user)
    fail 'User object not provided!' unless opennebula_user
    {
      id: opennebula_user['ID'].to_i,
      name: opennebula_user['TEMPLATE/NAME'],
      identities: canonical_user_identities(opennebula_user),
      email: opennebula_user['TEMPLATE/EMAIL'],
      groups: [
        opennebula_user['GNAME'], # TODO: more groups
      ],
    }
  end

  # Creates a canonical representation of user identities in array form.
  #
  # @param opennebula_user [OpenNebula::User] ONe user
  # @return [Array<String>] canonical representation of identities in array form
  def canonical_user_identities(opennebula_user)
    fail 'User object not provided!' unless opennebula_user
    identities = []

    identities << opennebula_user['TEMPLATE/KRB_PRINCIPAL']
    identities << opennebula_user['TEMPLATE/X509_DN'].split('|') if opennebula_user['TEMPLATE/X509_DN']
    identities << opennebula_user['NAME']
    identities << opennebula_user['ID'].to_s
    identities.flatten!
    identities.compact!

    identities
  end

  # Checks OpenNebula return codes for errors. Raises an error of the
  # provided type (class) if applicable.
  #
  # @param rc [Object] object to be checked
  # @param e_klass [Object] error class
  def check_retval(rc, e_klass = nil)
    return true unless ::OpenNebula.is_error?(rc)
    fail (e_klass ? e_klass : RuntimeError ), rc.message
  end

end
