extender.activate "apps/#{File.basename(Dir.pwd)}", :local => true,
    :only_if => defined?(Rails) || ENV.key?('RAILS_ENV')
