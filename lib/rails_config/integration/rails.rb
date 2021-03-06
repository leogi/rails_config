module RailsConfig
  module Integration
    module Rails
      if defined?(::Rails::Railtie)
        class Railtie < ::Rails::Railtie
          # Load rake tasks (eg. Heroku)
          rake_tasks do
            Dir[File.join(File.dirname(__FILE__),'../tasks/*.rake')].each { |f| load f }
          end

          # TODO: allo them to override init_callback via ENV or something?
          if ::Rails::VERSION::MAJOR >= 4 and ::Rails::VERSION::MINOR >= 1
            init_callback = :before_initialize
          else
            init_callback = :before_configuration
          end

          ActiveSupport.on_load init_callback, :yield => true do
            # Manually load the custom initializer before everything else
            initializer = ::Rails.root.join("config", "initializers", "rails_config.rb")
            require initializer if File.exist?(initializer)

            # Parse the settings before any of the initializers
            RailsConfig.load_and_set_settings(
              RailsConfig.setting_files(::Rails.root.join("config"), ::Rails.env)
            )
          end

          # Rails Dev environment should reload the Settings on every request
          if ::Rails.env.development?
            initializer :rails_config_reload_on_development do
              ActionController::Base.class_eval do
                prepend_before_filter { ::RailsConfig.reload! }
              end
            end
          end
        end
      end
    end
  end
end
