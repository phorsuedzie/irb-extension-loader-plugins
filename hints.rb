Module.new do
  HINTS = [
    "Forgot to store your last irb expression in a var? Don't worry - use '_':\n  keep = _",
  ]

  def self.init(extender)
    extender.notify "#{HINTS.shuffle.first}".gsub(/^/, "[Hint] ")
  end

  self
end.init(irb_extender)
