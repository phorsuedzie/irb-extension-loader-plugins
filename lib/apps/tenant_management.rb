irb_extender = self.irb_extender

Module.new.instance_eval do
  custom_config_file = File.expand_path("~/.config/infopark/tenant_management.json")

  if File.exist?(custom_config_file)
    require 'json'
    custom_config = JSON.parse(File.read(custom_config_file)).with_indifferent_access

    standard_config = TenantManagement::Application.config.api_auth
    standard_config.keys.each do |key|
      if custom_config.key?(key)
        irb_extender.notify "Using custom tenant_management configuration for #{key}"
        standard_config[key] = standard_config[key].with_indifferent_access.merge(custom_config[key])
      end
    end
  end
end
