require_relative 'base'

class BotFilter < BaseFilter
  BOT_PATTERNS = [
    /bot/i,
    /spider/i,
    /crawler/i,
    /scrape/i,
    /slurp/i,
    /ia_archiver/i,
    /curl/i,
    /python/i,
    /wget/i
  ]

  def apply(entries)
    entries.reject { |entry| bot?(entry.user_agent) }
  end

  private

  def bot?(user_agent)
    BOT_PATTERNS.any? { |pattern| user_agent.match?(pattern) }
  end
end
