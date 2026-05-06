#!/usr/bin/env ruby
require_relative 'lib/parser'
require_relative 'lib/filters/filter_chain'

log_file = ARGV[0] || 'fixtures/sample_logs.txt'
entries, invalid = Parser.parse(log_file)
puts "Parsed #{entries.length} entries (#{invalid} invalid lines)"

chain = FilterChain.new(128)
filtered, stats = chain.apply(entries)
puts "After filtering: #{filtered.length} entries remaining"
stats.each { |reason, count| puts "  #{reason}: #{count}" }
