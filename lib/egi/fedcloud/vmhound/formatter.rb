require 'terminal-table'

#
class Egi::Fedcloud::Vmhound::Formatter

  class << self
    #
    def as_table(data)
      data ||= []
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Transforming #{data.inspect} into a table"
      table = Terminal::Table.new

      table.add_row [
        ' >>> VM ID <<< ', ' >>> Owner <<< ', ' >>> VO/Group <<< ',
        ' >>> IPs <<< ', ' >>> Phys. location <<< ', ' >>> State <<< ',
        ' >>> Contact <<< '
      ]
      table.add_separator
      data.each do |vm|
        table.add_separator
        table.add_row [
          vm[:id], vm[:owner][:identities].join("\n"), vm[:group],
          vm[:ips].join("\n"), vm[:host], vm[:state], vm[:owner][:email]
        ]
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
