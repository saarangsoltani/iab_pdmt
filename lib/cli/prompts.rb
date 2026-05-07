require_relative 'input_reader'

class Prompts
  def self.welcome
    puts ''
    puts 'Welcome to CoHost Download Measurement Pipeline (IAB 2.2 Compliant)'
    puts '=' * 60
    puts ''
  end

  def self.get_log_file_path
    InputReader.ask('Enter path to CDN log file', 'fixtures/sample_logs.txt')
  end

  def self.get_output_format
    puts 'Select output format:'
    puts '  1) Human-readable text (default)'
    puts '  2) Table (terminal table)'
    puts '  3) CSV'
    puts '  4) JSON'
    puts ''

    InputReader.ask('Enter choice (1-4)', '1')
  end

  def self.get_bitrate
    InputReader.ask('Enter bitrate for 1-minute rule (kbps)', '128').to_i
  end
end
