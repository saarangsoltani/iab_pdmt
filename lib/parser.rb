require_relative 'models/log_entry'

class Parser
  def self.parse(file_path)
    entries = []
    invalid_lines = 0

    File.open(file_path, 'r') do |file|
      file.each_line do |line|
        line.strip!
        next if line.empty?

        fields = line.split('|')

        if fields.length == 12
          entries << LogEntry.new(fields)
        else
          invalid_lines += 1
        end
      end
    end

    [entries, invalid_lines]
  end
end
