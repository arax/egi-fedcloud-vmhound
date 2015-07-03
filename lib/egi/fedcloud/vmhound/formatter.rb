require 'terminal-table'

#
class Egi::Fedcloud::Vmhound::Formatter

  FORMATS = %w(table json plain).freeze
  LINE_SEPARATOR = "\n\t".freeze
  RECORD_SEPARATOR = "\n\n".freeze

  class << self
    #
    def as_table(data, opts = {})
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Transforming #{data.inspect} into a table"

      data ||= []
      table = Terminal::Table.new

      table.add_row [
        ' >>> VM ID <<< ', ' >>> Group <<< ', ' >>> Contact <<< ',
        ' >>> Host <<< ', ' >>> State <<< ',
      ]
      table.add_separator
      data.each do |vm|
        table.add_separator
        table.add_row [
          vm[:id], vm[:group], vm[:owner][:email],
          vm[:host], vm[:state]
        ]
      end

      table
    end

    #
    def as_json(data, opts = {})
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Transforming #{data.inspect} into a JSON document"
      return '{}' if data.blank?

      JSON.generate(data)
    end

    #
    def as_plain(data, opts = {})
      Egi::Fedcloud::Vmhound::Log.debug "[#{self}] Transforming #{data.inspect} into plain text"
      return '' if data.blank?

      lines = {}
      data.each do |vm|
        Egi::Fedcloud::Vmhound::Log.warn "[#{self}] #{vm[:owner][:name]} doesn't " \
                                            "have a contact e-mail! VM[#{vm[:id]}]" if vm[:owner][:email].blank?
        next if vm[:owner][:email].blank?

        line_key = "\"#{vm[:owner][:name]} in #{vm[:owner][:groups].first}\" <#{vm[:owner][:email]}>"
        lines[line_key] ||= []
        lines[line_key] << "#{vm[:id]} is #{vm[:state]} on #{vm[:host]}"
      end

      plain = []
      lines.each_pair do |line_key, line_vals|
        plain << "#{line_key}: #{line_vals.count} VMs#{LINE_SEPARATOR}#{line_vals.join LINE_SEPARATOR}"
      end
      plain.join RECORD_SEPARATOR
    end
  end

end
