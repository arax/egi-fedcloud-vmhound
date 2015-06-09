require 'terminal-table'

#
class Egi::Fedcloud::Vmhound::Formatter

  class << self
    #
    def as_table(data, opts = {})
      data ||= []
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Transforming #{data.inspect} into a table"
      table = Terminal::Table.new

      thead = [
        ' >>> VM ID <<< ', ' >>> Contact <<< ',
        ' >>> Location <<< ', ' >>> State <<< '
      ]
      thead.concat [
        ' >>> Owner Identity <<< ', ' >>> Group <<< ', ' >>> IPs <<< '
      ] if opts[:details]

      table.add_row thead
      table.add_separator
      data.each do |vm|
        table.add_separator
        tbody = [
          vm[:id], vm[:owner][:email], vm[:host], vm[:state]
        ]
        tbody.concat [
          vm[:owner][:identities].join("\n"),
          vm[:group], vm[:ips].join("\n")
        ] if opts[:details]
        table.add_row tbody
      end

      table
    end

    #
    def as_json(data, opts = {})
      data ||= []
      data ? JSON.generate(data) : '{}'
    end
  end

end
