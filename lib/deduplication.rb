require 'ipaddr'

class Deduplication
  WINDOW_SECONDS = 24 * 60 * 60

  def self.deduplicate(entries, bitrate_kbps = 128)
    grouped = entries.group_by { |e| dedup_key(e) }
    deduplicated = []

    grouped.each do |_key, grouped_entries|
      sorted = grouped_entries.sort_by(&:timestamp)
      window_start = nil
      window_entries = []

      sorted.each do |entry|
        timestamp_seconds = entry.timestamp / 1000.0

        if window_start.nil? || (timestamp_seconds - window_start) > WINDOW_SECONDS
          deduplicated << merge_window_entries(window_entries, bitrate_kbps) unless window_entries.empty?
          window_start = timestamp_seconds
          window_entries = [entry]
        else
          window_entries << entry
        end
      end

      deduplicated << merge_window_entries(window_entries, bitrate_kbps) unless window_entries.empty?
    end

    deduplicated
  end

  def self.merge_window_entries(entries, bitrate_kbps)
    total_bytes = entries.sum(&:bytes_sent)
    byte_threshold = (bitrate_kbps * 1000 * 60) / 8
    return unless total_bytes >= byte_threshold

    entries.max_by(&:bytes_sent)
  end

  def self.dedup_key(entry)
    ip_key = extract_ip_key(entry.ip_address)
    ua_key = entry.user_agent
    url_key = entry.episode_url
    "#{ip_key}|#{ua_key}|#{url_key}"
  end

  def self.extract_ip_key(ip_address)
    ip = IPAddr.new(ip_address)

    if ip.ipv6?
      native = ip.native
      if native.ipv4?
        native.to_s
      else
        ipv6_int = ip.to_i
        prefix_int = ipv6_int >> 64
        format('%04x:%04x:%04x:%04x',
               (prefix_int >> 48) & 0xffff,
               (prefix_int >> 32) & 0xffff,
               (prefix_int >> 16) & 0xffff,
               prefix_int & 0xffff)
      end
    else
      ip_address
    end
  rescue IPAddr::InvalidAddressError
    ip_address
  end
end
