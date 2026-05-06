require_relative '../filters/filter_chain'
require_relative '../deduplication'

class IabCompliance
  DEFAULT_BITRATE = 128

  def initialize(bitrate_kbps = DEFAULT_BITRATE)
    @bitrate_kbps = bitrate_kbps
    @byte_threshold = calculate_byte_threshold
  end

  def process(entries)
    filter_chain = FilterChain.new(@bitrate_kbps)
    filtered_entries, filter_stats = filter_chain.apply(entries)

    deduplicated = Deduplication.deduplicate(filtered_entries, @bitrate_kbps)

    per_episode = calculate_per_episode(deduplicated)

    {
      summary: {
        total_raw_requests: entries.length,
        total_filtered_out: entries.length - filtered_entries.length,
        filter_breakdown: filter_stats,
        total_compliant_downloads: deduplicated.compact.length
      },
      per_episode: per_episode,
      options_used: {
        bitrate: @bitrate_kbps,
        byte_threshold: @byte_threshold
      }
    }
  end

  private

  def calculate_byte_threshold
    (@bitrate_kbps * 1000 * 60) / 8
  end

  def calculate_per_episode(deduplicated)
    counts = Hash.new(0)
    deduplicated.compact.each do |entry|
      counts[entry.episode_url] += 1
    end
    counts.map { |url, count| { episode_url: url, downloads: count } }
  end
end
