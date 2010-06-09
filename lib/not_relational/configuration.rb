require "openssl"
require "logger"

module NotRelational
  class Configuration
    
    attr_reader :repository_class
    attr_reader :base_domain_name
    attr_reader :blob_bucket
    attr_reader :caching_bucket
    attr_reader :aws_key_id
    attr_reader :aws_secret_key
    attr_reader :memcache_servers
    attr_reader :use_seperate_domain_per_model
    attr_reader :fail_fast
    attr_reader :log_level
    attr_reader :data_filepath

    def self.singleton
      @singleton ||= NotRelational::Configuration.new
      return @singleton
    end

    def initialize()
      not_relational_config=find_config_section

      if not_relational_config
        if not_relational_config.has_key?("repository_class")
          @repository_class=eval  not_relational_config["repository_class"]
          unless @repository_class
            raise "Repository class not found: '#{not_relational_config["repository_class"]}'"
          end
        else
          @repository_class=NotRelational::MemoryRepository
        end
        @base_domain_name= not_relational_config["base_domain_name"] || ""
        @blob_bucket= not_relational_config["blob_bucket"]
        @caching_bucket= not_relational_config["caching_bucket"]
        @aws_key_id = not_relational_config["aws_key_id"]
        @aws_secret_key = not_relational_config["aws_secret_key"]
        @data_filepath= not_relational_config['data_filepath']
        @memcache_servers= not_relational_config['memcache_servers']
        @memcache_servers = memcache_servers.split(",") if memcache_servers and memcache_servers.respond_to?(:split)

        @use_seperate_domain_per_model=not_relational_config['use_seperate_domain_per_model']||false
        @fail_fast=not_relational_config['fail_fast'] ||false

        @cipher_password = not_relational_config['cipher_password']

        @log_level = Logger::WARN
        @log_level =eval( "Logger::"+not_relational_config["log_level"]) if not_relational_config["log_level"]
        
      end
    end

    def assert_configured
      return if @repository_class
      
      msg="NOT_RELATIONAL is not configured\n"
      msg << "config file: #{config_file_path}\n"
      msg << "config section: #{config_section_name}\n"
      config=find_config_section
      if config
        msg << "config: #{find_config_section.to_yml}\n"
      else
        msg << "config section not found\n"
      end
      
      raise msg
      
    end

    def logger
      unless @logger
        @logger = Logger.new(STDERR)
        @logger.level = @log_level
      end
      @logger
    end

    def  crypto
      return @crypto if @crypto
      if cipher_password
        @crypto=Crypto.new(cipher_password)
      else
        raise " 'cipher_password' value not found in config."
      end

    end
    def cipher_password
      return @cipher_password
    end
    def config_file_path
      unless @config_file_path
        if Object.const_defined?(:RAILS_ROOT)  and ENV.has_key?('RAILS_ENV')
          @config_file_path =  File.join("#{RAILS_ROOT}","config","database.yml")
        else
          if File.exists?("database.yml")

            @config_file_path = "database.yml"
          elsif File.exists?(File.join("config", "database.yml"))
            @config_file_path = File.join("config", "database.yml")
          end

        end
      end
      return @config_file_path
    end
    def config_section_name
      unless @config_section_name
        if Object.const_defined?(:RAILS_ROOT)  and ENV.has_key?('RAILS_ENV')
          @config_section_name =ENV['RAILS_ENV']+"_not_relational"

        else
          @config_section_name =(ENV['NOT_RELATIONAL_ENV'] || "test")+"_not_relational"
        end
      end
      return @config_section_name
    end
    
    def find_config_section
      return $not_relational_config if $not_relational_config

      
      if config_file_path and config_section_name
        config_file = YAML.load(File.open( config_file_path))
        $not_relational_config = config_file[config_section_name]

      end

      return $not_relational_config
    end
  end
end
