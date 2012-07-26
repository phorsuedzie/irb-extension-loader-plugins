# Tries to load an extender from plugin/libs with the same name as
# your current directory basename.
#
# Requires: Existence of Dir.pwd + "/lib"
# Skipped : If it looks like a Rails App


plugin_library "libs/#{File.basename(Dir.pwd)}"
