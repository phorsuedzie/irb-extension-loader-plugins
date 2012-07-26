Module.new.instance_eval do
  def self.notify(text)
    @extender.notify("[TM] #{text}")
  end

  def self.init(extender)
    @extender = extender
    extend extender.helper
    extend_configuration
    notify 't = dynamo.tables.create("cmdb-kai-test", 5, 5, {:hash_key => {:hash_key => :string}, :range_key => {:range_key => :string}})'
    notify 'Directory.dynamo_table.batch_get(:all, ["tenant/testkai"]).each {|i| p i}'
    notify 'CouchPotato.database.destroy(Tenant.all.first)'
    notify 't = Tenant.new(:name => "testkai", :title => "Kai Test", :owner => "kai", :password => "passw0rd").tap{|t| t.add_feature(S3BlobsFeature.new)}; CouchPotato.database.save(t)'
    notify 't.complete_feature(:s3)'
  end

  def self.extend_configuration
  #   name = "~/.config/infopark/tenant_management.json"
  #   custom_config_file = File.expand_path(name)

  #   if File.exist?(custom_config_file)
  #     notify "Extending configuration with #{name}"
  #     custom_config = Confstruct::Configuration.new(MultiJson.decode(File.read(custom_config_file)))
  #     custom_node_config_file_human = "~/.config/infopark/tenant_management/node.json"
  #     custom_node_config_file = File.expand_path(custom_node_config_file_human)
  #     if File.exist?(custom_node_config_file)
  #       notify "Extending configuration with #{custom_node_config_file_human}"
  #       node_config = Confstruct::Configuration.new(MultiJson.decode(File.read(custom_node_config_file)))
  #       custom_config = custom_config.deep_merge("node" => node_config)
  #     end

  #     config = Rails.application.config
  #     custom_config.each do |(key, value)|
  #       current = Rails.application.config.__send__(key.to_sym)
  #       patched =
  #           case current
  #           when Hash
  #             current.with_indifferent_access.deep_merge(MultiJson.decode(MultiJson.encode(value)))
  #           when Confstruct::HashWithStructAccess
  #             current.deep_merge(value)
  #           else
  #             value
  #           end
  #       Rails.application.config.__send__(:"#{key}=", patched)
  #       notify "Patched config.#{key}"
  #     end
  #   end
  end

  self
end.init(irb_extender)
