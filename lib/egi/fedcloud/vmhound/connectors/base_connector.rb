#
class Egi::Fedcloud::Vmhound::Connectors::BaseConnector

  # Initializes a connector instance.
  #
  # @param opts [Hash] options for the connector
  def initialize(opts = {})
    @options = opts.freeze
  end

  # Retrieves active instances from the underlying CMF. Including instances
  # in transitional or suspended states. Terminated instances will not be
  # included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def active_instances; end

  # Retrieves running instances from the underlying CMF. Only currently
  # running instances will be included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def running_instances; end

end
