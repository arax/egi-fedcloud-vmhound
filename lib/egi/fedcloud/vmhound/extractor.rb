require 'ipaddr'

#
class Egi::Fedcloud::Vmhound::Extractor

  class << self
    #
    def find_by_ip(ip, options = {})
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Searching for instances by IP: #{ip.inspect}"
    end

    #
    def find_by_appuri(uri, options = {})
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Searching for instances by MPURI: #{uri.inspect}"
    end

    #
    def find_by_user(id, options = {})
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Searching for instances by user ID: #{id.inspect}"
    end
  end

end
