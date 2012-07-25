helper = Module.new do
  module Helper
    def self.init(extender, plugin_config)
      @extender = extender
      @initializing = true
      @interactive = plugin_config[:interactive]
      notify("Get or activate/deactivate scalarium:\n   scalarium [true | false]")
      path = "~/.config/infopark/scalarium.json"
      include UserSwitching.init(path)
    end

    def self.ready
      @initializing = false
    end

    def self.interactive?
      @interactive
    end

    def self.initializing?
      @initializing
    end

    def self.display_options
      case
      when initializing?
        {:section => "Scalarium"}
      when interactive?
        {:noisy => true}
      end
    end

    def self.notify(text)
      @extender.notify(text, display_options)
    end

    def self.failure(text)
      interactive? or raise text
      warn(text)
    end

    def self.warn(text)
      @extender.warn(text, options)
    end

    class NoResource
      def initialize(url, *args)
        @url = url
      end

      def [](path)
        NoResource.new(@url + "/#{path}")
      end

      def get
        Helper.notify("GET #{@url}")
        '{}'
      end

      def post(data)
        Helper.notify("POST #{@url}: #{data}")
        data
      end

      def put(data)
        Helper.notify("PUT #{@url}: #{data}")
        data
      end

      def delete
        Helper.notify("DELETE #{@url}")
      end
    end

    # scalarium [true | false]
    def scalarium(*args)
      args.empty? and return ::Scalapi.scalarium
      ::Scalapi.configure do |config|
        config.resource = args.first ? nil : NoResource.new("https://no.scalarium.com/api")
      end
    end

    def clouds(selector = nil, options = nil)
      options ||= {}
      clouds = options[:clouds] || Scalapi.scalarium.clouds
      matching_clouds =
          case selector
          when :all
            clouds
          when String
            clouds.select {|c| c['name'].include?(selector)}
          when Regexp
            clouds.select {|c| c['name'] =~ selector}
          when 1..clouds.size
            [clouds[selector - 1]]
          when Fixnum
            Helper.failure("Index #{selector} out of range: 1..#{clouds.size}")
          end

      return matching_clouds unless Helper.interactive?
      return matching_clouds.first if matching_clouds && matching_clouds.size == 1
      return matching_clouds || [] if options[:all]

      selectable_clouds = matching_clouds || clouds

      format = "%#{selectable_clouds.size.to_s.length}d %s\n"
      menu = "\nChoose cloud:\n"
      selectable_clouds.each_with_index do |e, i|
        menu << format % [i + 1, e['name']]
      end
      menu << "Press 1 - #{selectable_clouds.size} or (q)uit\n"
      menu << "Answer: "
      print menu

      input = (STDIN.readline.strip)
      return selectable_clouds if input == "q"
      selector = input.to_i.to_s == input ? input.to_i : input
      return self.clouds(selector, :clouds => selectable_clouds)
    end

    def trace(*args)
      Scalapi.configure do |config|
        config.trace = args
      end
    end
  end

  module UserSwitching
    class Tokens

      attr_reader :users_and_tokens

      def read_tokens(path)
        return nil unless File.exist?(full_path = File.expand_path(path))
        Helper.notify "Info: using token(s) from #{path}"
        require 'json'
        custom_config = JSON.parse(File.read(full_path))
        tokens = custom_config.inject({}) do |memo, (key, value)|
          name, token =
              if key.to_s == "scalarium_token"
                [:"<default>", value]
              elsif (Hash === value) && (token = value["scalarium_token"])
               [key, token]
              end
          name and memo[name] = token
          memo
        end
        default = tokens[:"<default>"] or Helper.warn("Missing key 'scalarium_token' in #{path}")
        users = tokens.keys.reject{|k| Symbol === k}.sort
        users_and_tokens = users.map do |user|
          [user, tokens[user]]
        end
        users_and_tokens.unshift([:"<default>", default]) if default
        users_and_tokens
      end

      def initialize(path)
        @users_and_tokens = read_tokens(path) || []
      end

      def current_user(token)
        current_entry = users_and_tokens.detect do |(user, user_token)|
          token == user_token
        end

        current_user = current_entry.first

        unless current_user
          next_no_name = 1 + users_and_tokens.count do |(user, user_token)|
            user =~ /^no name #\d+$/
          end
          current_user = "no name ##{next_no_name}"
          users_and_tokens << [current_user, token]
        end

        current_user
      end

      def user_for_token(token)
        entry = users_and_tokens.detect do |(user, token_value)|
          token == token_value
        end
        entry && entry.first
      end

      def user_for_token_index(index)
        entry = users_and_tokens[index]
        entry && entry.first
      end

      def token_for_user(user)
        entry = users_and_tokens.detect do |(user_name, token)|
          user == user_name
        end
        entry && entry.last
      end

      def size
        users_and_tokens.size
      end

    end

    def self.init(token_path)
      @tokens = Tokens.new(token_path)
      Helper.notify("Fast token switch:\n   token [<token number>]")
      self
    end

    def self.tokens
      @tokens
    end

    def self.interactive?
      Helper.interactive?
    end

    def self.current_user
      token = Scalapi::Configuration.configuration.token rescue nil
      @tokens.current_user(token) if token
    end

    def self.setup_scalarium_token(token)
      ::Scalapi.configure do |config|
        config.token = token
      end
    end

    def self.menu
      current_user = self.current_user
      menu = "\nAvailable users:\n"
      @tokens.users_and_tokens.each_with_index do |(user, token), i|
        menu << "#{user == current_user ? "*" : " "} #{i + 1} #{user}\n"
      end
      menu << "Press 1 - #{@tokens.size} or (q)uit\n"
      menu << "Answer: "
    end

    def token(token_spec = nil, sub_call = false)
      unless Helper.interactive?
        token_spec or raise "Must provide a token specification"
      end

      tokens = UserSwitching.tokens
      user = nil
      token =
          case token_spec
          when Symbol
            token_spec.to_s
          when Fixnum
            user = tokens.user_for_token_index(token_spec - 1)
            user && tokens.token_for_user(user)
          when String
            user = token_spec
            tokens.token_for_user(user)
          else
            nil
          end

      if token
        user ||= tokens.user_for_token(token)
        if user == UserSwitching.current_user
          Helper.notify("=> Current user remains #{user}")
        else
          UserSwitching.setup_scalarium_token(token)
          Helper.notify("=> Current user is now #{user}")
        end
      elsif token_spec
        Helper.failure("Invalid token specification #{token_spec}")
      end

      return unless Helper.interactive?
      return if sub_call

      print UserSwitching.menu
      while input = STDIN.readline.strip
        case input
        when "", /^q/
          puts "Done."
          break
        else
          if (index = input.to_i) > 0
            if tokens.size > index - 1
              token(index, true)
              input = input[input.to_i.to_s.length..-1]
              redo if "q" == input
            else
              Helper.warn("Out of range: #{input}")
            end
          else
            Helper.warn("Bad input: #{input}")
          end
        end
        print UserSwitching.menu
      end
    end
  end

  def self.extend_scalapi_classes
    c = Module.new do
      def find_by_name(name)
        all.detect do |cloud|
          cloud['name'] == name
        end
      end

      def stop
        instances.each do |i|
          case i.status
          when "stopped", "terminating", "shutting-down"
            # skip
          else
            i.stop
          end
        end
      end
    end

    s = Module.new do
      def find_cloud_by_name(name)
        nested("clouds", :class => Scalapi::Cloud).find_by_name(name)
      end
    end

    Scalapi::Cloud.extend c
    Scalapi::Scalarium.__send__(:include, s)
    Helper.notify("Info: Injected Scalarium#find_cloud_by_name")

    a = Module.new do
      def method_missing(m, *args)
        args.empty? or return super
        @attributes or return super
        @attributes.include?(m.to_s) or return super
        @attributes[m.to_s]
      end

      def respond_to?(m)
        @attributes or return super
        @attributes.include?(m.to_s) or return super
        true
      end
    end

    Scalapi::Core::Attributes.__send__(:include, a)
    Helper.notify("Info: Injected method access to resource attributes")
  end


  def self.init(extender, plugin_config)
    Helper.init(extender, plugin_config)
    default_token = UserSwitching.tokens.token_for_user(:"<default>") ||
        (UserSwitching.tokens.size == 1 && UserSwitching.tokens.users_and_tokens.first.last)
    default_token and Scalapi.configure {|config| config.token = default_token}

    trace = plugin_config[:trace] and Scalapi.configure do |config|
      begin
        config.trace = trace
        Helper.notify("Activated tracing: #{trace.inspect}")
      rescue
        Helper.warn("Resource tracing not supported")
      end
    end

    extend_scalapi_classes

    Helper.ready

    Helper
  end

  self
end.init(irb_extender, irb_config[:scalarium] || {})

extend helper # Yes, this is (unnamed module)::Helper as returned by (unnamed module).init
