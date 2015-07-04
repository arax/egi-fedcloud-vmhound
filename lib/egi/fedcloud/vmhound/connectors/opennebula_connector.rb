require 'opennebula'

#
class Egi::Fedcloud::Vmhound::Connectors::OpennebulaConnector < Egi::Fedcloud::Vmhound::Connectors::BaseConnector

  # Initializes a connector instance.
  #
  # @param opts [Hash] options for the connector
  def initialize(opts = {})
    super

    options = {}
    options[:sync] = true
    # TODO: fix https://github.com/OpenNebula/one/blob/ced1a29bfb3f3d1991ea88e658ea9462071fe4b8/src/oca/ruby/opennebula/client.rb#L166
    #options[:cert_dir] = opts[:ca_path] unless opts[:ca_path].blank?
    options[:disable_ssl_verify] = opts[:insecure]

    initialize_pools initialize_secret(opts), opts, options
  end

  # Retrieves active instances from the underlying OpenNebula. Including instances
  # in transitional or suspended states. Terminated instances will not be
  # included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def instances
    Egi::Fedcloud::Vmhound::Log.info "[#{self.class}] Retrieving active instances"
    fetch_instances
  end

  # Retrieves running instances from the underlying OpenNebula. Only currently
  # running instances will be included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def active_instances
    Egi::Fedcloud::Vmhound::Log.info "[#{self.class}] Retrieving running instances"
    fetch_instances ['ACTIVE']
  end

  private

  # Processes options and extracts the secret used to connect to
  # OpenNebula. This can be username & password, file with a token,
  # or nothing (`nil`).
  #
  # @param opts [Hash] hash with options
  # @return [NilClass, String] constructed secret
  def initialize_secret(opts = {})
    secret = if opts[:username] && opts[:password]
               Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Using provided plain credentials"
               "#{opts[:username]}:#{opts[:password]}"
             else
               Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Falling back to file and environment credentials"
               opts[:auth_file] ? File.read(opts[:auth_file]) : nil
             end
    secret.strip! if secret
    secret
  end

  # Initializes client instance and corresponding OpenNebula
  # resource pools and caches.
  #
  # @param secret [String, NilClass] authentication secret
  # @param opts [Hash] user-defined options
  # @param options [Hash] computed options for ONe client
  # @return [NilClass] nothing
  def initialize_pools(secret, opts = {}, options = {})
    client = OpenNebula::Client.new(secret, opts[:endpoint], options)

    @vm_pool = OpenNebula::VirtualMachinePool.new(client)
    @vm_pool_ary = nil

    @image_pool = OpenNebula::ImagePool.new(client)
    @canonical_image_pool = nil

    @user_pool = OpenNebula::UserPool.new(client)
    @canonical_user_pool = nil
  end

  # Retrieves a list of instances matching given criteria.
  #
  # @param allow_states [Array<String>] a list of allowed states
  # @param reject_states [Array<String>] a list of states to be rejected
  # @return [Array<Hash>] a list of instances matching given criteria
  def fetch_instances(allow_states = nil, reject_states = nil)
    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Retrieving instances: " \
                                      "allow_states=#{allow_states.inspect} & " \
                                      "reject_states=#{reject_states.inspect}"
    return if allow_states && allow_states.empty?
    reject_states ||= []

    @vm_pool_ary = fetch_instances_batch_pool(@vm_pool) unless @vm_pool_ary

    vms = []
    @vm_pool_ary.each do |vm|
      if reject_states.include? vm.state_str
        Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Rejecting VM #{vm['ID']} " \
                                          "-- #{vm.state_str}"
        next
      end

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
  def fetch_instances_batch_pool(vm_pool)
    fail 'Pool object not provided!' unless vm_pool
    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Iterating over the VM " \
                                      "pool without batch processing"

    check_retval vm_pool.info(
      OpenNebula::VirtualMachinePool::INFO_ALL,
      -1, -1,
      OpenNebula::VirtualMachinePool::INFO_NOT_DONE
    )
    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Got #{vm_pool.count.inspect} VMs from pool"

    vm_pool.to_a
  end

  # Retrieves a list of images.
  #
  # @return [Array<Hash>] a list of images
  def images
    return @canonical_image_pool if @canonical_image_pool
    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Retrieving all images"
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
    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Picking image ID #{image_id.inspect} from pool"
    images.select { |image| image[:id] == image_id.to_i }.first
  end

  # Retrieves a list of users.
  #
  # @return [Array<Hash>] a list of users
  def users
    return @canonical_user_pool if @canonical_user_pool
    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Retrieving all users"
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
    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Picking user ID #{user_id.inspect} from pool"
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
      group: opennebula_instance['GNAME'],
      owner: user_by_id(opennebula_instance['UID']),
      appliance: image_by_id(opennebula_instance['TEMPLATE/DISK[1]/IMAGE_ID']),
      ips: canonical_instance_ips(opennebula_instance),
      identifiers: canonical_instance_identifiers(opennebula_instance),
      host: canonical_instance_host(opennebula_instance),
      state: "#{opennebula_instance.state_str} - #{opennebula_instance.lcm_state_str}",
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

    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Assigning IPs #{ips.inspect} " \
                                      "to #{opennebula_instance['ID'].inspect}"
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

    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Assigning instance IDs " \
                                      "#{identifiers.inspect} to #{opennebula_instance['ID'].inspect}"
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

    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Assigning hosts #{hosts.inspect} " \
                                      "to #{opennebula_instance['ID'].inspect}"
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

    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Assigning IDs #{identifiers.inspect} " \
                                      "to image #{opennebula_image['ID'].inspect}"
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
      name: opennebula_user['TEMPLATE/NAME'] || opennebula_user['NAME'],
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

    Egi::Fedcloud::Vmhound::Log.debug "[#{self.class}] Assigning identities #{identities.inspect} " \
                                      "to user #{opennebula_user['ID'].inspect}"
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
