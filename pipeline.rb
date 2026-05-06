#!/usr/bin/env ruby
require_relative 'lib/parser'

log_file = ARGV[0] || 'fixtures/sample_logs.txt'
entries, invalid = Parser.parse(log_file)
puts "Parsed #{entries.length} entries (#{invalid} invalid lines)"
