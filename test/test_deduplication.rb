require_relative 'test_helper'
require_relative '../lib/deduplication'

class TestDeduplication < TestHelper
  def test_dedup_key_ipv4
    entry = LogEntry.new(@sample_line.split('|'))
    key = Deduplication.dedup_key(entry)
    assert key.start_with?('127.0.0.1|')
    assert key.include?(entry.user_agent)
    assert key.include?(entry.episode_url)
  end

  def test_dedup_key_ipv6
    ipv6_line = @sample_line.sub('127.0.0.1', '2001:0db8:85a3:0000:0000:8a2e:0370:7334')
    entry = LogEntry.new(ipv6_line.split('|'))
    key = Deduplication.dedup_key(entry)
    assert key.start_with?('2001:0db8:85a3:0000|')
  end

  def test_dedup_key_invalid_ip
    line = @sample_line.sub('127.0.0.1', 'not_an_ip')
    entry = LogEntry.new(line.split('|'))
    key = Deduplication.dedup_key(entry)
    assert key.start_with?('not_an_ip|')
  end

  def test_deduplicate_within_window
    fields = @sample_line.split('|')
    fields[3] = '1000000'
    entry1 = LogEntry.new(fields)
    fields2 = fields.dup
    fields2[2] = (entry1.timestamp + 1000).to_s
    entry2 = LogEntry.new(fields2)
    result = Deduplication.deduplicate([entry1, entry2])
    assert_equal 1, result.length
  end

  def test_deduplicate_outside_window
    fields = @sample_line.split('|')
    fields[3] = '1000000'
    entry1 = LogEntry.new(fields)
    fields2 = fields.dup
    fields2[2] = (entry1.timestamp + (25 * 60 * 60 * 1000)).to_s
    entry2 = LogEntry.new(fields2)
    result = Deduplication.deduplicate([entry1, entry2])
    assert_equal 2, result.length
  end

  def test_deduplicate_different_ips
    fields1 = @sample_line.split('|')
    fields1[3] = '1000000'
    fields1[5] = '192.168.1.1'
    entry1 = LogEntry.new(fields1)
    fields2 = fields1.dup
    fields2[5] = '192.168.1.2'
    entry2 = LogEntry.new(fields2)
    result = Deduplication.deduplicate([entry1, entry2])
    assert_equal 2, result.length
  end

  def test_deduplicate_multiple_entries_in_window
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    entry1 = LogEntry.new(fields)
    entry2 = LogEntry.new(fields.dup.tap { |f| f[2] = (entry1.timestamp + 3_600_000).to_s })
    entry3 = LogEntry.new(fields.dup.tap { |f| f[2] = (entry1.timestamp + 7_200_000).to_s })
    result = Deduplication.deduplicate([entry1, entry2, entry3])
    assert_equal 1, result.length
    assert_equal 5_000_000, result.first.bytes_sent
  end

  def test_deduplicate_multiple_206_below_threshold
    fields = @sample_line.split('|')
    fields[1] = '206'
    fields[4] = '5000000'
    fields[3] = '300000'
    entry1 = LogEntry.new(fields)
    entry2 = LogEntry.new(fields.dup.tap { |f| f[2] = (entry1.timestamp + 5000).to_s })
    entry3 = LogEntry.new(fields.dup.tap { |f| f[2] = (entry1.timestamp + 10_000).to_s })
    result = Deduplication.deduplicate([entry1, entry2, entry3], 128)
    assert_equal 1, result.length
    assert_nil result.first
  end

  def test_deduplicate_multiple_206_meets_threshold
    fields = @sample_line.split('|')
    fields[1] = '206'
    fields[4] = '5000000'
    fields[3] = '350000'
    entry1 = LogEntry.new(fields)
    entry2 = LogEntry.new(fields.dup.tap { |f| f[2] = (entry1.timestamp + 5000).to_s })
    entry3 = LogEntry.new(fields.dup.tap { |f| f[2] = (entry1.timestamp + 10_000).to_s })
    result = Deduplication.deduplicate([entry1, entry2, entry3], 128)
    assert_equal 1, result.length
    refute_nil result.first
    assert_equal 350_000, result.first.bytes_sent
  end
end
