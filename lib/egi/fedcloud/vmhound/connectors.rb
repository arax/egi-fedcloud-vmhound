# Load base connector first
require File.join(File.dirname(__FILE__), 'connectors', "base_connector")

# Load all available connectors
Dir.glob(File.join(File.dirname(__FILE__), 'connectors', "*.rb")) { |connector_file| require connector_file.chomp('.rb') }
