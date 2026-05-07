require_relative 'formatter'

class CsvFormatter < Formatter
  def format(results)
    output = []
    summary = results[:summary]

    output << '# SUMMARY'
    output << "total_raw_requests,#{summary[:total_raw_requests]}"
    output << "total_filtered_out,#{summary[:total_filtered_out]}"
    output << "compliant_downloads,#{summary[:total_compliant_downloads]}"

    summary[:filter_breakdown].each do |reason, count|
      output << "#{reason},#{count}"
    end

    options = results[:options_used]
    output << "bitrate_kbps,#{options[:bitrate]}"
    output << "byte_threshold,#{options[:byte_threshold]}"

    output << ''
    output << '# PER EPISODE'
    output << 'episode_url,downloads'

    results[:per_episode].each do |ep|
      output << "#{ep[:episode_url]},#{ep[:downloads]}"
    end

    output.join("\n")
  end
end
