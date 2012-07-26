def rails_detect(version, detector)
  expression = detector[version] and return expression.call || false
  version and raise "Unexpected rails version test: #{version}"
  detector.values.detect {|expression| expression.call} && true || false
end

def rails_app?(version = nil)
  rails_detect(version, {
    3 => lambda {File.exist?(Dir.pwd + "/config/application.rb")},
    2 => lambda {File.exist?(Dir.pwd + "/config/environment.rb") && !rails_app?(3)},
  })
end

def rails?(version = nil)
  rails_detect(version, {
    2 => lambda {rails_app?(2) && ::ENV.key?('RAILS_ENV')},
    3 => lambda {rails_app?(3) && defined?(Rails)},
  })
end
