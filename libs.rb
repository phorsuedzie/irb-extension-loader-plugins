# Tries to load an extender from plugin/libs with the same name as
# your current directory basename.
#
# Requires: Existence of Dir.pwd + "/lib"
# Skipped : If it looks like a Rails App


irb_activate "libs/#{File.basename(Dir.pwd)}", :local => true,
    :only_if => !irb_helper.rails_app? && File.exist?(Dir.pwd + "/lib")
