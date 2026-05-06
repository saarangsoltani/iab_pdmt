require_relative 'test_helper'
require_relative '../lib/filters/filter_chain'
require_relative '../lib/filters/http_status_filter'
require_relative '../lib/filters/bot_filter'
require_relative '../lib/filters/apple_watch_filter'
require_relative '../lib/filters/audio_request_filter'
require_relative '../lib/filters/byte_threshold_filter'

class TestFilters < TestHelper
  def setup
    super
    fields_200 = @sample_line.split('|')
    fields_200[1] = '200'
    fields_200[3] = '461957'
    @entry_200 = LogEntry.new(fields_200)

    fields_206 = @sample_line.split('|')
    fields_206[1] = '206'
    fields_206[3] = '1000000'
    @entry_206_good = LogEntry.new(fields_206)

    fields_206_bad = @sample_line.split('|')
    fields_206_bad[1] = '206'
    fields_206_bad[3] = '5000'
    @entry_206_bad = LogEntry.new(fields_206_bad)

    fields_bot = @sample_line.split('|')
    fields_bot[9] = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
    @entry_bot = LogEntry.new(fields_bot)

    fields_watch = @sample_line.split('|')
    fields_watch[9] = 'Podcasts/4025.400.1 CFNetwork/3860.400.51 watchOS/10.0'
    @entry_watch = LogEntry.new(fields_watch)

    fields_non_audio = @sample_line.split('|')
    fields_non_audio[1] = '200'
    fields_non_audio[3] = '5000000'
    fields_non_audio[7] = 'https://audio-delivery.cohostpodcasting.com/audio/show/page.html'
    @entry_non_audio = LogEntry.new(fields_non_audio)
  end

  def test_http_status_filter
    filter = HttpStatusFilter.new
    result = filter.apply([@entry_200, @entry_206_good])
    assert_equal 2, result.length
  end

  def test_http_status_filter_rejects_404
    filter = HttpStatusFilter.new
    fields = @sample_line.split('|')
    fields[1] = '404'
    result = filter.apply([LogEntry.new(fields)])
    assert_equal 0, result.length
  end

  def test_http_status_filter_rejects_500
    filter = HttpStatusFilter.new
    fields = @sample_line.split('|')
    fields[1] = '500'
    result = filter.apply([LogEntry.new(fields)])
    assert_equal 0, result.length
  end

  def test_http_status_filter_rejects_301
    filter = HttpStatusFilter.new
    fields = @sample_line.split('|')
    fields[1] = '301'
    result = filter.apply([LogEntry.new(fields)])
    assert_equal 0, result.length
  end

  def test_bot_filter_googlebot
    filter = BotFilter.new
    result = filter.apply([@entry_bot, @entry_200])
    assert_equal 1, result.length
    assert_equal 200, result.first.http_status
  end

  def test_bot_filter_curl
    filter = BotFilter.new
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    fields[9] = 'curl/7.68.0'
    entry = LogEntry.new(fields)
    result = filter.apply([entry, @entry_200])
    assert_equal 1, result.length
  end

  def test_bot_filter_python
    filter = BotFilter.new
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    fields[9] = 'Python/3.10 requests/2.28.0'
    entry = LogEntry.new(fields)
    result = filter.apply([entry, @entry_200])
    assert_equal 1, result.length
  end

  def test_bot_filter_spider
    filter = BotFilter.new
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    fields[9] = 'Mozilla/5.0 (compatible; bingbot/2.0)'
    entry = LogEntry.new(fields)
    result = filter.apply([entry, @entry_200])
    assert_equal 1, result.length
  end

  def test_bot_filter_wget
    filter = BotFilter.new
    fields = @sample_line.split('|')
    fields[1] = '200'
    fields[3] = '5000000'
    fields[9] = 'Wget/1.21'
    entry = LogEntry.new(fields)
    result = filter.apply([entry, @entry_200])
    assert_equal 1, result.length
  end

  def test_audio_request_filter_mp3_allowed
    filter = AudioRequestFilter.new
    result = filter.apply([@entry_200])
    assert_equal 1, result.length
  end

  def test_audio_request_filter_rejects_non_audio
    filter = AudioRequestFilter.new
    result = filter.apply([@entry_non_audio])
    assert_equal 0, result.length
  end

  def test_audio_request_filter_rejects_html
    filter = AudioRequestFilter.new
    fields = @sample_line.split('|')
    fields[7] = 'https://audio-delivery.cohostpodcasting.com/index.html'
    entry = LogEntry.new(fields)
    result = filter.apply([entry])
    assert_equal 0, result.length
  end

  def test_apple_watch_filter
    filter = AppleWatchFilter.new
    result = filter.apply([@entry_watch, @entry_200])
    assert_equal 1, result.length
    assert_equal 200, result.first.http_status
  end

  def test_byte_threshold_filter_200_auto_passes
    filter = ByteThresholdFilter.new(128)
    result = filter.apply([@entry_200])
    assert_equal 1, result.length
  end

  def test_byte_threshold_filter_206_good
    filter = ByteThresholdFilter.new(128)
    result = filter.apply([@entry_206_good])
    assert_equal 1, result.length
  end

  def test_byte_threshold_filter_206_bad
    filter = ByteThresholdFilter.new(128)
    result = filter.apply([@entry_206_bad])
    assert_equal 0, result.length
  end

  def test_byte_threshold_custom_bitrate
    filter = ByteThresholdFilter.new(64)
    fields = @sample_line.split('|')
    fields[1] = '206'
    fields[3] = '500000'
    entry = LogEntry.new(fields)
    result = filter.apply([entry])
    assert_equal 1, result.length
  end

  def test_filter_chain
    chain = FilterChain.new(128)
    entries = [@entry_200, @entry_206_good, @entry_206_bad, @entry_bot, @entry_watch]
    filtered, stats = chain.apply(entries)
    assert_equal 2, filtered.length
    assert_equal 1, stats['bot']
    assert_equal 1, stats['apple_watch']
    assert_equal 1, stats['below_byte_threshold']
  end
end
