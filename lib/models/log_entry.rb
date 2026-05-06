class LogEntry
  attr_reader :cache_status, :http_status, :timestamp, :bytes_sent, :file_size,
              :ip_address, :referer, :url, :region, :user_agent, :request_id, :country

  def initialize(fields)
    @cache_status = fields[0]
    @http_status = fields[1].to_i
    @timestamp = fields[2].to_i
    @bytes_sent = fields[3].to_i
    @file_size = fields[4].to_i
    @ip_address = fields[5]
    @referer = fields[6]
    @url = fields[7]
    @region = fields[8]
    @user_agent = fields[9]
    @request_id = fields[10]
    @country = fields[11]
  end

  def episode_url
    url.split('?').first
  end

  def to_h
    {
      cache_status: cache_status,
      http_status: http_status,
      timestamp: timestamp,
      bytes_sent: bytes_sent,
      file_size: file_size,
      ip_address: ip_address,
      referer: referer,
      url: url,
      region: region,
      user_agent: user_agent,
      request_id: request_id,
      country: country
    }
  end
end
