#!/usr/bin/env ruby
# Generate realistic sample CDN logs for testing

require 'securerandom'
require 'date'

def generate_timestamp
  (Time.now - rand(0..172_800)).to_i * 1000
end

def generate_ip
  case rand(0..10)
  when 0..7
    Array.new(4) { rand(1..255) }.join('.')
  else
    "2001:#{rand(0x1000..0xFFFF)}:#{rand(0x1000..0xFFFF)}:#{rand(0x1000..0xFFFF)}:#{rand(0x1000..0xFFFF)}:#{rand(0x1000..0xFFFF)}:#{rand(0x1000..0xFFFF)}"
  end
end

def generate_user_agent
  agents = [
    'Podcasts/4025.400.1 CFNetwork/3860.400.51 Darwin/25.3.0',
    'Overcast/1.0 (iPhone; iOS 17.0)',
    'Spotify/8.7.0 (iPhone; iOS 17.0)',
    'AppleCoreMedia/1.0.0.21A340 (iPhone; U; CPU OS 17_0 like Mac OS X)',
    'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
    'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)',
    'Podcasts/4025.400.1 CFNetwork/3860.400.51 watchOS/10.0',
    'Pocket Casts/7.0 (Android 14)',
    'Castro/2.0 (iPhone; iOS 16.0)',
    'Brendan/1.0 (Bot)',
    'curl/7.68.0',
    'Python/3.10 requests/2.28.0'
  ]
  agents.sample
end

def generate_episode_url
  shows = %w[tech_talk news_daily sports_wrap science_corner]
  episodes = %w[ep1_intro ep2_deep_dive ep3_special ep4_finale ep5_bonus]

  show = shows.sample
  episode = episodes.sample
  "https://audio-delivery.cohostpodcasting.com/audio/#{show}/episodes/#{episode}/episode.mp3?v=#{SecureRandom.hex(8)}"
end

def generate_http_status
  case rand(0..100)
  when 0..60 then 200
  when 61..90 then 206
  when 91..93 then 404
  when 94..95 then 500
  when 96..97 then 301
  else 206
  end
end

def generate_bytes_sent(http_status, file_size)
  if http_status == 200
    file_size
  elsif http_status == 206
    case rand(0..10)
    when 0..3
      rand(1..500_000)
    when 4..7
      rand(500_001..1_500_000)
    else
      file_size
    end
  else
    0
  end
end

def generate_cache_status
  %w[HIT MISS HIT MISS BYPASS].sample
end

def generate_country
  %w[US CA GB AU DE FR JP BR IN MX].sample
end

def generate_region(country)
  regions = {
    'US' => %w[CA NY TX IL FL WA],
    'CA' => %w[ON BC QC AB],
    'GB' => %w[ENG SCT WLS],
    'AU' => %w[NSW VIC QLD WA]
  }
  (regions[country] || ['Unknown']).sample
end

LISTENER_PROFILES = []
50.times do
  ip = generate_ip
  ua = generate_user_agent
  LISTENER_PROFILES << { ip: ip, user_agent: ua }
end

EPISODE_URLS = []
20.times do
  EPISODE_URLS << generate_episode_url
end

output_path = File.join(File.dirname(__FILE__), 'fixtures', 'sample_logs.txt')
puts 'Generating 1000 sample log entries...'

File.open(output_path, 'w') do |file|
  created_entries = []

  1000.times do |_i|
    entry_type = rand(0..100)

    if entry_type < 10 && !created_entries.empty?
      base = created_entries.sample
      cache_status = generate_cache_status
      http_status = generate_http_status
      timestamp = base[:timestamp] + rand(1..82_800) * 1000
      file_size = base[:file_size]
      bytes_sent = generate_bytes_sent(http_status, file_size)
      ip = base[:ip]
      referer = base[:referer]
      url = base[:url]
      region = base[:region]
      user_agent = base[:user_agent]
      request_id = SecureRandom.hex(16)
      country = base[:country]

    elsif entry_type < 15 && !created_entries.empty?
      base = created_entries.sample
      cache_status = generate_cache_status
      http_status = generate_http_status
      timestamp = base[:timestamp] + rand(90_000..172_800) * 1000
      file_size = base[:file_size]
      bytes_sent = generate_bytes_sent(http_status, file_size)
      ip = base[:ip]
      referer = base[:referer]
      url = base[:url]
      region = base[:region]
      user_agent = base[:user_agent]
      request_id = SecureRandom.hex(16)
      country = base[:country]

    elsif entry_type < 20 && !created_entries.empty?
      base = created_entries.sample
      cache_status = generate_cache_status
      http_status = 206
      timestamp = base[:timestamp] + rand(1..3600) * 1000
      file_size = base[:file_size]
      bytes_sent = rand(100_000..500_000)
      ip = base[:ip]
      referer = base[:referer]
      url = base[:url]
      region = base[:region]
      user_agent = base[:user_agent]
      request_id = SecureRandom.hex(16)
      country = base[:country]

    else
      cache_status = generate_cache_status
      http_status = generate_http_status
      timestamp = generate_timestamp
      file_size = rand(5_000_000..50_000_000)
      bytes_sent = generate_bytes_sent(http_status, file_size)
      profile = LISTENER_PROFILES.sample
      ip = profile[:ip]
      user_agent = profile[:user_agent]
      referer = rand > 0.3 ? '-' : 'https://example.com/podcast'
      url = EPISODE_URLS.sample
      country = generate_country
      region = generate_region(country)
      request_id = SecureRandom.hex(16)
    end

    entry_data = {
      timestamp: timestamp,
      ip: ip,
      user_agent: user_agent,
      url: url,
      file_size: file_size,
      referer: referer,
      region: region,
      country: country
    }
    created_entries << entry_data

    line = [
      cache_status,
      http_status,
      timestamp,
      bytes_sent,
      file_size,
      ip,
      referer,
      url,
      region,
      user_agent,
      request_id,
      country
    ].join('|')

    file.puts(line)
  end
end

puts 'Done! Generated fixtures/sample_logs.txt with 1000 entries'
