require 'terminal-table'

#
class Egi::Fedcloud::Vmhound::Formatter

  class << self
    #
    def as_table(data)
      data ||= []
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Transforming #{data.inspect} into a table"
      table = Terminal::Table.new

      table.add_row [' >>> VM ID <<< ', ' >>> Owner <<< ', ' >>> Phys. location <<< ', ' >>> State <<< ']
      table.add_separator
      data.each do |vm|
        table.add_separator
        table.add_row [vm[:id], vm[:owner], vm[:host], vm[:state]]
      end

      table
    end

    #
    def as_json(data)
      data ||= []
      data ? JSON.generate(data) : '{}'
    end
  end

end
