require_relative '../filters/filter_chain'
require_relative '../deduplication'

class IabCompliance
  DEFAULT_BITRATE = 128

  def initialize(bitrate_kbps = DEFAULT_BITRATE)
    @bitrate_kbps = bitrate_kbps
    @byte_threshold = calculate_byte_threshold
  end

  def process(entries)
    # Step 1: Apply filters
    filter_chain = FilterChain.new
    filtered_entries, filter_stats = filter_chain.apply(entries)

    # Step 2: Deduplicate
    deduplicated, below_threshold = Deduplication.deduplicate(filtered_entries, @bitrate_kbps)
    filter_stats['below_byte_threshold'] = below_threshold

    # Step 3: Generate per-episode counts
    per_episode = calculate_per_episode(deduplicated)

    # Summary
    {
      summary: {
        total_raw_requests: entries.length,
        total_filtered_out: entries.length - filtered_entries.length,
        filter_breakdown: filter_stats,
        total_compliant_downloads: deduplicated.length
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
    deduplicated.each do |entry|
      counts[entry.episode_url] += 1
    end
    counts.map { |url, count| { episode_url: url, downloads: count } }
  end
end
