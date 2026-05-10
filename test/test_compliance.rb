require_relative 'test_helper'
require_relative '../lib/compliance/iab_2_2'
require_relative '../lib/filters/apple_watch_filter'
require_relative '../lib/filters/bot_filter'
require_relative '../lib/filters/http_status_filter'

class TestCompliance < TestHelper
  def setup
    super
    @compliance = IabCompliance.new(128)
  end

  def valid_entry
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    LogEntry.new(fields)
  end

  def test_process_basic
    entries = [valid_entry] * 10
    result = @compliance.process(entries)
    assert_equal 10, result[:summary][:total_raw_requests]
    assert_equal 1, result[:summary][:total_compliant_downloads]
  end

  def test_process_filters_bots
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    fields[9] = 'Mozilla/5.0 (compatible; Googlebot/2.1)'
    bot_entry = LogEntry.new(fields)
    entries = [bot_entry, valid_entry]
    result = @compliance.process(entries)
    assert_equal 1, result[:summary][:filter_breakdown]['bot']
    assert_equal 1, result[:summary][:total_compliant_downloads]
  end

  def test_process_filters_apple_watch
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    fields[9] = 'Podcasts/4025.400.1 CFNetwork/3860.400.51 watchOS/10.0'
    watch_entry = LogEntry.new(fields)
    entries = [watch_entry, valid_entry]
    result = @compliance.process(entries)
    assert_equal 1, result[:summary][:filter_breakdown]['apple_watch']
    assert_equal 1, result[:summary][:total_compliant_downloads]
  end

  def test_process_filters_invalid_status
    fields = @sample_line.split('|')
    fields[1] = '404'
    bad_entry = LogEntry.new(fields)
    entries = [bad_entry, valid_entry]
    result = @compliance.process(entries)
    assert_equal 1, result[:summary][:filter_breakdown]['non_200_206_status']
    assert_equal 1, result[:summary][:total_compliant_downloads]
  end

  def test_process_filters_below_threshold
    fields = @sample_line.split('|')
    fields[1] = '206'
    fields[3] = '5000'
    low_entry = LogEntry.new(fields)
    entries = [low_entry]
    result = @compliance.process(entries)
    assert_equal 1, result[:summary][:filter_breakdown]['below_byte_threshold']
    assert_equal 0, result[:summary][:total_compliant_downloads]
  end

  def test_process_dedup_happens
    entries = [valid_entry] * 5
    result = @compliance.process(entries)
    assert_equal 5, result[:summary][:total_raw_requests]
    assert_equal 1, result[:summary][:total_compliant_downloads]
  end

  def test_process_per_episode_counts
    entry1 = valid_entry
    entry2 = valid_entry
    result = @compliance.process([entry1, entry2])
    expected_url = 'https://audio-delivery.cohostpodcasting.com/audio/example_show_id/episodes/example_episode_id/episode.mp3'
    assert_equal 1, result[:per_episode].length
    assert_equal expected_url, result[:per_episode].first[:episode_url]
    assert_equal 1, result[:per_episode].first[:downloads]
  end

  def test_process_options_used
    compliance = IabCompliance.new(64)
    result = compliance.process([valid_entry])
    assert_equal 64, result[:options_used][:bitrate]
    assert_equal 480_000, result[:options_used][:byte_threshold]
  end
end
