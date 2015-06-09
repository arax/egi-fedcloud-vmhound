require 'ipaddr'

#
class Egi::Fedcloud::Vmhound::Extractor

  class << self

    # @param options [Hash] hash with connector options
    # @return [String] name of the initialized connector
    def env_init(options = {})
      fail 'Connector type not specified!' unless options[:cmf]
      return if defined?(@@connector)

      connector_name = "#{options[:cmf].camelize}Connector"
      @@connector = Egi::Fedcloud::Vmhound::Connectors.const_get(connector_name).new(options)

      connector_name
    end

    #
    def find_by_ip(ip, options = {})
      env_init options
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Searching for instances by IP: #{ip.inspect}"
    end

    #
    def find_by_appuri(uri, options = {})
      env_init options
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Searching for instances by MPURI: #{uri.inspect}"
    end

    #
    def find_by_user(id, options = {})
      env_init options
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Searching for instances by user ID: #{id.inspect}"
    end
  end

end
