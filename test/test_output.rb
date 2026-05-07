require_relative 'test_helper'
require_relative '../lib/output/human_readable_formatter'
require_relative '../lib/output/json_formatter'
require_relative '../lib/output/csv_formatter'
require_relative '../lib/output/table_formatter'

class TestOutput < TestHelper
  def setup
    @results = {
      summary: {
        total_raw_requests: 100,
        total_filtered_out: 40,
        filter_breakdown: {
          'non_200_206_status' => 10,
          'bot' => 15,
          'apple_watch' => 5,
          'non_audio_request' => 3,
          'below_byte_threshold' => 7
        },
        total_compliant_downloads: 5
      },
      per_episode: [
        { episode_url: 'https://example.com/ep1.mp3', downloads: 3 },
        { episode_url: 'https://example.com/ep2.mp3', downloads: 2 }
      ],
      options_used: {
        bitrate: 128,
        byte_threshold: 960_000
      }
    }
  end

  def test_human_readable_includes_summary
    output = HumanReadableFormatter.new.format(@results)
    assert output.include?('IAB 2.2 COMPLIANT DOWNLOAD MEASUREMENT RESULTS')
    assert output.include?('Total Raw Requests: 100')
    assert output.include?('Total Filtered Out: 40')
    assert output.include?('Compliant Downloads: 5')
  end

  def test_human_readable_includes_filter_breakdown
    output = HumanReadableFormatter.new.format(@results)
    assert output.include?('FILTER BREAKDOWN')
    assert output.include?('non_200_206_status: 10')
    assert output.include?('bot: 15')
    assert output.include?('apple_watch: 5')
    assert output.include?('non_audio_request: 3')
    assert output.include?('below_byte_threshold: 7')
  end

  def test_human_readable_includes_per_episode
    output = HumanReadableFormatter.new.format(@results)
    assert output.include?('PER EPISODE')
    assert output.include?('https://example.com/ep1.mp3: 3 downloads')
    assert output.include?('https://example.com/ep2.mp3: 2 downloads')
  end

  def test_human_readable_includes_options
    output = HumanReadableFormatter.new.format(@results)
    assert output.include?('OPTIONS USED')
    assert output.include?('Bitrate: 128 kbps')
    assert output.include?('Byte Threshold: 960000 bytes')
  end

  def test_json_is_valid_json
    output = JsonFormatter.new.format(@results)
    parsed = JSON.parse(output)
    assert_equal 100, parsed['summary']['total_raw_requests']
    assert_equal 40, parsed['summary']['total_filtered_out']
    assert_equal 5, parsed['summary']['total_compliant_downloads']
  end

  def test_json_includes_all_sections
    output = JsonFormatter.new.format(@results)
    parsed = JSON.parse(output)
    assert parsed.key?('summary')
    assert parsed.key?('per_episode')
    assert parsed.key?('options_used')
    assert_equal 2, parsed['per_episode'].length
    assert_equal 128, parsed['options_used']['bitrate']
    assert_equal 960_000, parsed['options_used']['byte_threshold']
  end

  def test_json_filter_breakdown
    output = JsonFormatter.new.format(@results)
    parsed = JSON.parse(output)
    breakdown = parsed['summary']['filter_breakdown']
    assert_equal 10, breakdown['non_200_206_status']
    assert_equal 15, breakdown['bot']
    assert_equal 5, breakdown['apple_watch']
    assert_equal 3, breakdown['non_audio_request']
    assert_equal 7, breakdown['below_byte_threshold']
  end

  def test_csv_includes_summary
    output = CsvFormatter.new.format(@results)
    assert output.include?('total_raw_requests,100')
    assert output.include?('total_filtered_out,40')
    assert output.include?('compliant_downloads,5')
  end

  def test_csv_includes_filter_breakdown
    output = CsvFormatter.new.format(@results)
    assert output.include?('bot,15')
    assert output.include?('non_200_206_status,10')
    assert output.include?('apple_watch,5')
  end

  def test_csv_includes_options
    output = CsvFormatter.new.format(@results)
    assert output.include?('bitrate_kbps,128')
    assert output.include?('byte_threshold,960000')
  end

  def test_csv_includes_per_episode
    output = CsvFormatter.new.format(@results)
    assert output.include?('# PER EPISODE')
    assert output.include?('episode_url,downloads')
    assert output.include?('https://example.com/ep1.mp3,3')
    assert output.include?('https://example.com/ep2.mp3,2')
  end

  def test_table_includes_summary
    output = TableFormatter.new.format(@results)
    assert output.include?('Total Raw Requests:')
    assert output.include?('Total Filtered Out:')
    assert output.include?('Compliant Downloads:')
    assert output.include?('100')
    assert output.include?('40')
    assert output.include?('5')
  end

  def test_table_includes_filter_breakdown
    output = TableFormatter.new.format(@results)
    assert output.include?('FILTER BREAKDOWN')
    assert output.include?('bot: 15')
    assert output.include?('non_200_206_status: 10')
  end

  def test_table_includes_options
    output = TableFormatter.new.format(@results)
    assert output.include?('OPTIONS')
    assert output.include?('128 kbps')
    assert output.include?('960000 bytes')
  end

  def test_table_includes_episode_downloads
    output = TableFormatter.new.format(@results)
    assert output.include?('EPISODE DOWNLOADS')
    assert output.include?('https://example.com/ep1.mp3')
    assert output.include?('https://example.com/ep2.mp3')
    assert output.include?('| 3')
    assert output.include?('| 2')
  end

  def test_empty_per_episode
    results = @results.dup
    results[:per_episode] = []
    results[:summary][:total_compliant_downloads] = 0
    output = HumanReadableFormatter.new.format(results)
    assert output.include?('PER EPISODE')
    output = JsonFormatter.new.format(results)
    parsed = JSON.parse(output)
    assert_equal [], parsed['per_episode']
  end

  def test_large_bitrate_values
    results = @results.dup
    results[:options_used] = { bitrate: 320, byte_threshold: 2_400_000 }
    output = HumanReadableFormatter.new.format(results)
    assert output.include?('320 kbps')
    assert output.include?('2400000 bytes')
    output = JsonFormatter.new.format(results)
    parsed = JSON.parse(output)
    assert_equal 320, parsed['options_used']['bitrate']
  end

  def test_formatter_base_class
    assert_raises(NotImplementedError) do
      Formatter.new.format(@results)
    end
  end
end
