require_relative 'test_helper'

class TestParser < TestHelper
  def test_parse_single_line
    File.open('/tmp/test_parser.txt', 'w') { |f| f.puts(@sample_line) }
    entries, invalid = Parser.parse('/tmp/test_parser.txt')
    assert_equal 1, entries.length
    assert_equal 0, invalid
    entry = entries.first
    assert_equal 'HIT', entry.cache_status
    assert_equal 206, entry.http_status
    assert_equal 1_772_668_799_339, entry.timestamp
    assert_equal 146_943, entry.bytes_sent
    assert_equal 461_957, entry.file_size
    assert_equal '127.0.0.1', entry.ip_address
    assert_equal 'https://audio-delivery.cohostpodcasting.com/audio/example_show_id/episodes/example_episode_id/episode.mp3?v=fb6eb08ac7',
                 entry.url
    assert_equal 'IL', entry.region
    assert_equal 'Podcasts/4025.400.1 CFNetwork/3860.400.51 Darwin/25.3.0', entry.user_agent
    assert_equal '74175026932da740fb68d8856080d0f6', entry.request_id
    assert_equal 'US', entry.country
  end

  def test_parse_ipv6_address
    ipv6_line = @sample_line.sub('127.0.0.1', '2001:0db8:85a3:0000:0000:8a2e:0370:7334')
    File.open('/tmp/test_parser_ipv6.txt', 'w') { |f| f.puts(ipv6_line) }
    entries, = Parser.parse('/tmp/test_parser_ipv6.txt')
    assert_equal '2001:0db8:85a3:0000:0000:8a2e:0370:7334', entries.first.ip_address
  end

  def test_parse_http_200
    line_200 = @sample_line.sub('|206|', '|200|')
    File.open('/tmp/test_parser_200.txt', 'w') { |f| f.puts(line_200) }
    entries, = Parser.parse('/tmp/test_parser_200.txt')
    assert_equal 200, entries.first.http_status
  end

  def test_parse_http_404
    line_404 = @sample_line.sub('|206|', '|404|')
    File.open('/tmp/test_parser_404.txt', 'w') { |f| f.puts(line_404) }
    entries, = Parser.parse('/tmp/test_parser_404.txt')
    assert_equal 404, entries.first.http_status
  end

  def test_episode_url_removes_query_params
    File.open('/tmp/test_parser_ep.txt', 'w') { |f| f.puts(@sample_line) }
    entries, = Parser.parse('/tmp/test_parser_ep.txt')
    expected = 'https://audio-delivery.cohostpodcasting.com/audio/example_show_id/episodes/example_episode_id/episode.mp3'
    assert_equal expected, entries.first.episode_url
  end

  def test_parse_invalid_lines
    File.open('/tmp/test_parser_invalid.txt', 'w') do |f|
      f.puts(@sample_line)
      f.puts('ONLY|ONE|Field')
      f.puts(@sample_line)
    end
    entries, invalid = Parser.parse('/tmp/test_parser_invalid.txt')
    assert_equal 2, entries.length
    assert_equal 1, invalid
  end

  def test_parse_empty_lines
    File.open('/tmp/test_parser_empty.txt', 'w') do |f|
      f.puts @sample_line
      f.puts ''
      f.puts '   '
      f.puts @sample_line
    end
    entries, invalid = Parser.parse('/tmp/test_parser_empty.txt')
    assert_equal 2, entries.length
    assert_equal 0, invalid
  end

  def test_parse_special_chars_in_user_agent
    line = @sample_line.sub('Podcasts/4025.400.1', 'Podcasts/1.0 (Mac OS X; Intel) AppleWebKit/537.36')
    File.open('/tmp/test_parser_ua.txt', 'w') { |f| f.puts(line) }
    entries, = Parser.parse('/tmp/test_parser_ua.txt')
    assert entries.first.user_agent.include?('AppleWebKit')
  end
end
