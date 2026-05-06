require_relative 'base'

class AppleWatchFilter < BaseFilter
  def apply(entries)
    entries.reject { |entry| watchos?(entry.user_agent) }
  end

  private

  def watchos?(user_agent)
    user_agent.match?(/watchos/i)
  end
end
