# Support for a self-written scalarium library

require 'lib/scalarium'

helper = Module.new do
  module Helper
    def self.init(extender)
      @extender = extender
      notify("Get or activate/deactivate scalarium:\n   scalarium [true | false]")
    end

    def self.notify(text)
      @extender.notify("[Scalarium] #{text}")
    end

    def self.warn(text)
      @extender.warn("[Scalarium] #{text}")
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

    def scalarium(*args)
      args.empty? and return ::Scalarium.scalarium
      ::Scalarium.configure do |config|
        config.resource = args.first ? nil : NoResource.new("https://no.scalarium.com/api")
      end
    end
  end

  module UserSwitching
    def self.init(tokens)
      self.tokens = tokens
      Helper.notify("Fast token switch:\n   token [<token number>]")
      self
    end

    def self.tokens=(tokens)
      default = tokens.delete(:default)
      @tokens = tokens
      @users = tokens.keys.sort
      if default
        @users.unshift(:default)
        tokens[:default] = default
      end
    end

    def self.tokens
      @tokens
    end

    def self.current_user
      token = Scalarium::Configuration.configuration.token
      if token
        current = users.detect do |user|
          tokens[user] == token
        end
        unless current
          no_names = users.select {|n| n =~ /^no name #\d+$/}
          current = "no name ##{no_names.size + 1}"
          self.tokens = tokens.merge(current => token)
        end
        current
      end
    end

    def self.users
      @users
    end

    def self.setup_scalarium_token(token)
      ::Scalarium.configure do |config|
        config.token = token
      end
    end

    def self.menu
      current_user == UserSwitching.current_user
      menu = "\nAvailable users:\n"
      users.each_with_index do |e, i|
        menu << "#{e == current_user ? "*" : " "} #{i + 1} #{e}\n"
      end
      menu << "Press 1 - #{users.size} or (q)uit\n"
      menu << "Answer: "
    end

    def token(index = nil)
      if String === index
        UserSwitching.setup_scalarium_token(index)
        return
      end

      current_user = UserSwitching.current_user
      tokens = UserSwitching.tokens
      users = UserSwitching.users

      if index
        user = users[index - 1]
        if user
          unless user == current_user
            token = tokens[user]
            UserSwitching.setup_scalarium_token(token)
            puts "=> Current user is now #{user}"
          end
          return
        end
      end

      print UserSwitching.menu
      while input = STDIN.readline.strip
        case input
        when "", /^q/
          puts "Done."
          break
        else
          if (index = input.to_i) > 0
            if users.size > index - 1
              token(index)
              input = input[input.to_i.to_s.length..-1]
              redo if "q" == input
            else
              puts "! Out of range: #{input} !"
            end
          else
            puts "! Bad input: #{input} !"
          end
        end
        print UserSwitching.menu
      end
    end
  end

  def self.read_credentials(path)
    require 'json'
    custom_config = JSON.parse(File.read(path))
    custom_config.inject({}) do |memo, (key, value)|
      if key.to_s == "scalarium_token"
        memo[:default] = value
      elsif (Hash === value) && (token = value["scalarium_token"])
        memo[key] = token
      end
      memo
    end
  end

  def self.extend_cloud_classes
    ::Scalarium::Cloud.instance_eval do
      def find_by_name(name)
        all.detect do |cloud|
          cloud['name'] == name
        end
      end
      Helper.notify("Info: Injected Cloud.find_by_name")
    end
  end

  def self.init(extender, plugin_config)
    Helper.init(extender)
    path = "~/.config/infopark/scalarium.json"
    if (File.exist?(full_path = File.expand_path(path)))
      Helper.notify "Info: using token(s) from #{path}"
      tokens = read_credentials(full_path)
      unless tokens.size < 2
        Helper.__send__(:include, UserSwitching.init(tokens))
      end
    else
      tokens = {}
    end

    Scalarium.configure do |config|
      config.token = tokens[:default] or Helper.warn("Missing key 'scalarium_token' in #{path}")
      if (trace = plugin_config[:trace])
        begin
          config.trace = trace
          Helper.notify("Activated tracing: #{trace.inspect}")
        rescue
          Helper.warn("Resource tracing not supported")
        end
      end
    end

    extend_cloud_classes

    Helper
  end

  self
end.init(irb_extender, self.irb_config[:scalarium] || {})

extend helper # Yes, this is (unnamed module)::Helper as returned by init
