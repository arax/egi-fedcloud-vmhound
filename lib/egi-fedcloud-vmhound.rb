# Initialize modules, if necessary
module Egi; end
module Egi::Fedcloud; end
module Egi::Fedcloud::Vmhound; end
module Egi::Fedcloud::Vmhound::Connectors; end

require 'active_support'
require 'active_support/core_ext'
require 'active_support/json'
require 'active_support/inflector'
require 'active_support/notifications'

require 'egi/fedcloud/vmhound/version'
require 'egi/fedcloud/vmhound/settings'
require 'egi/fedcloud/vmhound/log'
require 'egi/fedcloud/vmhound/connectors'
require 'egi/fedcloud/vmhound/formatter'
require 'egi/fedcloud/vmhound/extractor'
