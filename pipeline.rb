#!/usr/bin/env ruby
require_relative 'lib/cli/runner'

if ARGV.empty?
  Cli.new.run
else
  log_file = ARGV[0]
  format_choice = ARGV[1] || nil
  bitrate = ARGV[2] ? ARGV[2].to_i : nil
  Cli.new.run_with_args(log_file, format_choice, bitrate)
end
