class InputReader
  def self.ask(prompt, default = nil)
    if default
      print "#{prompt} [default: #{default}]: "
    else
      print "#{prompt}: "
    end

    input = gets
    input = input.nil? ? '' : input.chomp.strip
    input.empty? && default ? default : input
  end
end
