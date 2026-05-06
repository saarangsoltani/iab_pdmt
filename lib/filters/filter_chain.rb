require_relative 'http_status_filter'
require_relative 'bot_filter'
require_relative 'apple_watch_filter'
require_relative 'audio_request_filter'
require_relative 'byte_threshold_filter'

class FilterChain
  def initialize(bitrate_kbps = 128)
    @bitrate_kbps = bitrate_kbps
  end

  def apply(entries)
    stats = {
      'non_200_206_status' => 0,
      'bot' => 0,
      'apple_watch' => 0,
      'non_audio_request' => 0,
      'below_byte_threshold' => 0
    }

    filtered = entries.dup

    filtered = HttpStatusFilter.new.apply(filtered)
    stats['non_200_206_status'] = entries.length - filtered.length if filtered.length < entries.length

    bot_filtered = BotFilter.new.apply(filtered)
    stats['bot'] = filtered.length - bot_filtered.length
    filtered = bot_filtered

    watch_filtered = AppleWatchFilter.new.apply(filtered)
    stats['apple_watch'] = filtered.length - watch_filtered.length
    filtered = watch_filtered

    audio_filtered = AudioRequestFilter.new.apply(filtered)
    stats['non_audio_request'] = filtered.length - audio_filtered.length
    filtered = audio_filtered

    byte_filtered = ByteThresholdFilter.new(@bitrate_kbps).apply(filtered)
    stats['below_byte_threshold'] = filtered.length - byte_filtered.length
    filtered = byte_filtered

    [filtered, stats]
  end
end
