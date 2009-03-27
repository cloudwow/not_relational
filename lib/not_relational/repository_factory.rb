require "not_relational/sdb_repository.rb"
require "not_relational/configuration.rb"
require "not_relational/memory_repository.rb"
    
module NotRelational
  class RepositoryFactory
    def self.clear
      @repository=nil
      $not_relational_config=nil
      $repository=nil
    end

    def self.instance=(repo)
      @repository=repo
    end
    
    def self.instance(options={})

      if options and options.has_key?(:repository)
        return options[:repository]
      end
      
      return @repository if @repository

      config=NotRelational::Configuration.singleton
      
      options[:fail_fast]=config.fail_fast
      @repository= config.repository_class.new(
        config.base_domain_name,
        config.blob_bucket,
        config.aws_key_id,
        config.aws_secret_key,
        config.memcache_servers,
        nil,
        config.use_seperate_domain_per_model,
        options)
      
    end



    def self.set_repository(repository)
      @repository=repository
    end

  end
  #  def self.qualified_const_get(str)
  #    path = str.to_s.split('::')
  #    from_root = path[0].empty?
  #    if from_root
  #      from_root = []
  #      path = path[1..-1]
  #    else
  #      start_ns = ((Class === self)||(Module === self)) ? self : self.class
  #      from_root = start_ns.to_s.split('::')
  #    end
  #    until from_root.empty?
  #      begin
  #        return (from_root+path).inject(Object) { |ns,name| ns.const_get(name) }
  #      rescue NameError
  #        from_root.delete_at(-1)
  #      end
  #    end
  #    path.inject(Object) { |ns,name| ns.const_get(name) }
  #  end
end

