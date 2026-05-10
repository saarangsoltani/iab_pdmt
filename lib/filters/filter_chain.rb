require_relative 'http_status_filter'
require_relative 'bot_filter'
require_relative 'apple_watch_filter'
require_relative 'audio_request_filter'

class FilterChain
  def apply(entries)
    stats = {
      'non_200_206_status' => 0,
      'bot' => 0,
      'apple_watch' => 0,
      'non_audio_request' => 0
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

    [filtered, stats]
  end
end
