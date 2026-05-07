require 'json'
require_relative 'formatter'

class JsonFormatter < Formatter
  def format(results)
    results.to_json
  end
end
