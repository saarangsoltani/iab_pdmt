require_relative 'base'

class HttpStatusFilter < BaseFilter
  VALID_STATUSES = [200, 206]

  def apply(entries)
    entries.select do |entry|
      VALID_STATUSES.include?(entry.http_status)
    end
  end
end
