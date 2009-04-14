require "openssl"


module NotRelational
  class Configuration
  
    attr_reader :repository_class
    attr_reader :base_domain_name
    attr_reader :blob_bucket
    attr_reader :aws_key_id
    attr_reader :aws_secret_key
    attr_reader :memcache_servers
    attr_reader :use_seperate_domain_per_model
    attr_reader :fail_fast
    attr_reader :log_level

    attr_reader :cipher_key_file
    attr_reader :cipher_iv_file

    def self.singleton
      @singleton ||= NotRelational::Configuration.new
      return @singleton
    end

    def initialize()
      not_relational_config=find_config_section

      if not_relational_config
        if not_relational_config.has_key?("repository_class")
          @repository_class=eval  not_relational_config["repository_class"]
        else
          @repository_class=NotRelational::MemoryRepository
        end
        @base_domain_name= not_relational_config["base_domain_name"] || ""
        @blob_bucket= not_relational_config["blob_bucket"]
        @aws_key_id = not_relational_config["aws_key_id"]
        @aws_secret_key = not_relational_config["aws_secret_key"]
        @memcache_servers= not_relational_config['memcache_servers']
        @memcache_servers = memcache_servers.split(",") if memcache_servers and memcache_servers.respond_to?(:split)

        @use_seperate_domain_per_model=not_relational_config['use_seperate_domain_per_model']||false
        @fail_fast=not_relational_config['fail_fast'] ||false

        @cipher_key_file = not_relational_config['cipher_key_file']
        @cipher_key_file ||= "./.cipher_key"
        if @cipher_key_file and File.exists?(@cipher_key_file)
          @cipher_key=File.open(@cipher_key_file).read
        end

        @cipher_iv_file=not_relational_config['cipher_iv_file']
        @cipher_iv_file ||= "./cipher_iv"
        if @cipher_iv_file and File.exists?(@cipher_iv_file)
          @cipher_iv=File.open(@cipher_iv_file).read
        end
      @log_level = not_relational_config["log_level"] || Logger::INFO
        
      end
    end
    def  crypto
      return @crypto if @crypto
      options={}
      if cipher_key
        options[:cipher_key=]= cipher_key
        options[:cipher_iv  ]= cipher_iv
        @crypto=Crypto.new()
      else
        @crypto=Crypto.new
        File.open(self.cipher_key_file,'w').write(@crypto.key)
        File.open(self.cipher_iv_file,'w').write(@crypto.iv)
      end
    end
    def cipher_key
      return @cipher_key
    end

    def cipher_iv
      return @cipher_iv
    end

    def find_config_section
      return $not_relational_config if $not_relational_config
      config_file_path=nil
      config_section=nil

      # #when using rails use config/database.yml
      if Object.const_defined?(:RAILS_ROOT)  and ENV.has_key?('RAILS_ENV')
        config_file_path =  File.join("#{RAILS_ROOT}","config","database.yml")

        config_section =ENV['RAILS_ENV']+"_not_relational"



      else
        # #when not using rails use try database.yml then try
        # config/database.yml

        if File.exists?("database.yml")

          config_file_path = "database.yml"
        elsif File.exists?(File.join("config", "database.yml"))
          config_file_path = File.join("config", "database.yml")
        end

        config_section =(ENV['NOT_RELATIONAL_ENV'] || "production")+"_not_relational"
      end
      if config_file_path and config_section
        config_file = YAML.load(File.open( config_file_path))

        $not_relational_config = config_file[config_section]
      end
      return $not_relational_config
    end
  end
end