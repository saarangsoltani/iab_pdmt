require_relative 'base'

class ByteThresholdFilter < BaseFilter
  DEFAULT_BITRATE_KBPS = 128

  def initialize(bitrate_kbps = DEFAULT_BITRATE_KBPS)
    @bitrate_kbps = bitrate_kbps
    @byte_threshold = calculate_threshold
  end

  def apply(entries)
    entries.select { |entry| meets_threshold?(entry) }
  end

  private

  def calculate_threshold
    (@bitrate_kbps * 1000 * 60) / 8
  end

  def meets_threshold?(entry)
    if entry.http_status == 200
      true
    elsif entry.http_status == 206
      entry.bytes_sent >= @byte_threshold
    else
      false
    end
  end
end
