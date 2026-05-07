require_relative 'formatter'

class HumanReadableFormatter < Formatter
  def format(results)
    output = []
    output << '=' * 60
    output << 'IAB 2.2 COMPLIANT DOWNLOAD MEASUREMENT RESULTS'
    output << '=' * 60
    output << ''

    summary = results[:summary]
    output << 'SUMMARY:'
    output << "  Total Raw Requests: #{summary[:total_raw_requests]}"
    output << "  Total Filtered Out: #{summary[:total_filtered_out]}"
    output << "  Compliant Downloads: #{summary[:total_compliant_downloads]}"
    output << ''

    output << 'FILTER BREAKDOWN:'
    summary[:filter_breakdown].each do |reason, count|
      output << "  #{reason}: #{count}"
    end
    output << ''

    output << 'PER EPISODE:'
    results[:per_episode].each do |ep|
      output << "  #{ep[:episode_url]}: #{ep[:downloads]} downloads"
    end
    output << ''

    output << 'OPTIONS USED:'
    output << "  Bitrate: #{results[:options_used][:bitrate]} kbps"
    output << "  Byte Threshold: #{results[:options_used][:byte_threshold]} bytes"
    output << '=' * 60

    output.join("\n")
  end
end
