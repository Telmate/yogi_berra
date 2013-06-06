require 'mongo'
require 'facets'

module YogiBerra
  class Catcher
    extend Facets
    cattr_accessor :settings, :mongo_client, :connection

    class << self
      def load_db_settings(config_file = nil)
        if config_file
          database_config = config_file
        elsif defined?(Rails)
          database_config = "#{Rails.root}/config/yogi.yml"
        else
          YogiBerra::Logger.log("No config file specified!", :error)
        end
        if database_config
          begin
            File.open(database_config, 'r') do |f|
              yaml_file = YAML.load(f)
              environment = (ENV["YOGI_ENV"] || ENV["RAILS_ENV"] || "test")
              @@settings = yaml_file["#{environment}"] if yaml_file
            end
          rescue
            YogiBerra::Logger.log("No such file: #{database_config}", :error)
          end
          @@settings
        end
      end

      def db_client(host, port)
        # :w => 0 set the default write concern to 0, this allows writes to be non-blocking
        # by not waiting for a response from mongodb
        @@mongo_client = Mongo::MongoClient.new(host, port, :w => 0)
      rescue
        YogiBerra::Logger.log("Couldn't connect to the mongo database on host: #{host} port: #{port}.", :error)
        nil
      end

      def quick_connection
        load_db_settings unless @@settings

        if @@settings
          host = @@settings["host"]
          port = @@settings["port"]
          client = db_client(host, port)
          if client
            @@connection = client[@@settings["database"]]
          else
            YogiBerra::Logger.log("Couldn't connect to the mongo database on host: #{host} port: #{port}.", :error)
          end
        else
          YogiBerra::Logger.log("Couldn't load the yogi.yml file.", :error)
        end
        @@connection
      end
    end
  end
end