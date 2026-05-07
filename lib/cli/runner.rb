require_relative '../parser'
require_relative '../compliance/iab_2_2'
require_relative '../output/human_readable_formatter'
require_relative '../output/json_formatter'
require_relative '../output/csv_formatter'
require_relative '../output/table_formatter'
require_relative 'prompts'

class Cli
  def run
    Prompts.welcome
    log_file = Prompts.get_log_file_path

    unless File.exist?(log_file)
      puts "Error: File '#{log_file}' not found."
      return
    end

    format_choice = Prompts.get_output_format
    bitrate = Prompts.get_bitrate

    process_and_output(log_file, format_choice, bitrate)
  end

  private

  def process_and_output(log_file, format_choice, bitrate)
    puts ''
    puts 'Processing logs...'
    puts ''

    entries, invalid_count = Parser.parse(log_file)
    puts "Parsed #{entries.length} entries (#{invalid_count} invalid lines)"
    puts ''

    compliance = IabCompliance.new(bitrate)
    results = compliance.process(entries)

    formatter = case format_choice
                when '2'
                  TableFormatter.new
                when '3'
                  CsvFormatter.new
                when '4'
                  JsonFormatter.new
                else
                  HumanReadableFormatter.new
                end

    puts formatter.format(results)
  end
end
