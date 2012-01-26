# if defined?(Rails)
#   def show_sql
#     # do the same for Rails3
#   end
# else
  def show_sql
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.clear_reloadable_connections!
  end
# end
