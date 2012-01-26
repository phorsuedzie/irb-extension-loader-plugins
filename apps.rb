# Tries to load an extender from plugin/apps with the same name as
# your current directory basename.
#
# Requires: Dir.pwd should look like a rails app
# Requires: Rails is active in this process

irb_extender.activate "apps/#{File.basename(Dir.pwd)}", :local => true,
    :only_if => irb_helper.rails?
