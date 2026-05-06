require_relative 'base'

class AudioRequestFilter < BaseFilter
  def apply(entries)
    entries.select { |entry| audio_request?(entry.url) }
  end

  private

  def audio_request?(url)
    url.match?(/\.mp3(\?|$)/i) || url.match?(/\.m4a(\?|$)/i) || url.match?(/\.aac(\?|$)/i)
  end
end
