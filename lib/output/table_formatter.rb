require_relative 'formatter'

class TableFormatter < Formatter
  def format(results)
    output = []
    summary = results[:summary]
    options = results[:options_used]

    output << 'SUMMARY'
    output << '-' * 40
    output << "  Total Raw Requests:   #{summary[:total_raw_requests]}"
    output << "  Total Filtered Out:   #{summary[:total_filtered_out]}"
    output << "  Compliant Downloads:  #{summary[:total_compliant_downloads]}"
    output << ''

    output << 'FILTER BREAKDOWN'
    output << '-' * 40
    summary[:filter_breakdown].each do |reason, count|
      output << "  #{reason}: #{count}"
    end
    output << ''

    output << 'OPTIONS'
    output << '-' * 40
    output << "  Bitrate:         #{options[:bitrate]} kbps"
    output << "  Byte Threshold:  #{options[:byte_threshold]} bytes"
    output << ''

    output << 'EPISODE DOWNLOADS'
    output << '-' * 90
    output << 'Episode URL'.ljust(80) + ' | Downloads'
    output << '-' * 90

    results[:per_episode].each do |ep|
      url = ep[:episode_url].length > 80 ? ep[:episode_url][0..79] : ep[:episode_url]
      output << url.ljust(80) + " | #{ep[:downloads]}"
    end

    output.join("\n")
  end
end
