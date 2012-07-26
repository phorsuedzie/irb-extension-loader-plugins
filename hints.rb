def self.init(loader)
  hints = [
    "Forgot to store your last irb expression in a var? Don't worry - use '_':\n  keep = _",
  ]
  loader.notify "#{hints.shuffle.first}", :section => "Hint"
end
