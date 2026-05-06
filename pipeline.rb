#!/usr/bin/env ruby
require_relative 'lib/parser'
require_relative 'lib/compliance/iab_2_2'

log_file = ARGV[0] || 'fixtures/sample_logs.txt'
entries, invalid = Parser.parse(log_file)
puts "Parsed #{entries.length} entries (#{invalid} invalid lines)"

compliance = IabCompliance.new(128)
results = compliance.process(entries)
puts "Total Raw Requests: #{results[:summary][:total_raw_requests]}"
puts "Total Filtered Out: #{results[:summary][:total_filtered_out]}"
puts "Compliant Downloads: #{results[:summary][:total_compliant_downloads]}"
