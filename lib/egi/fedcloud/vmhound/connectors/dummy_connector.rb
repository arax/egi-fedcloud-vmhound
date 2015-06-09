#
class Egi::Fedcloud::Vmhound::Connectors::DummyConnector < Egi::Fedcloud::Vmhound::Connectors::BaseConnector

  # Retrieves active instances from the underlying Dummy. Including instances
  # in transitional or suspended states. Terminated instances will not be
  # included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def active_instances
    []
  end

  # Retrieves running instances from the underlying Dummy. Only currently
  # running instances will be included.
  #
  # @return [Array<Hash>] List of instances, each represented as a hash
  def running_instances
    []
  end

end
