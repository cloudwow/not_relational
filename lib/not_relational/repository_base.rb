module NotRelational
  class RepositoryBase
    def blob_bucket
      return @blob_bucket || ""
    end
    def blob_bucket=(val)
      @blob_bucket=val
    end

    def cache_write_only=(val)
      @cache_write_only=val
    end

    def cache_write_only
      if  @cache_write_only==nil || @cache_write_only==true
        return true
      else
        return false
      end
    end
    
    def persist_cache_peek(key)
      return nil if cache_write_only
      return short_cache("PersistantCacheCache/"+key) do
        result_yaml= NotRelational::Repository.storage.get(self.blob_bucket,"persistant_cache/"+ key  )
        if result_yaml
          YAML::load( result_yaml)
        else
          nil
        end
      end
    end
    
    def persist_cache_put(key,value)
      NotRelational::Repository.storage.put(self.blob_bucket,"persistant_cache/"+  key,value.to_yaml,{'Content-Type' => 'text/yaml' })
      short_cache_put(key,value)
    end
    
    def persist_cache_me(key,force_refresh=false)

      if force_refresh==true
        puts "force refresh for key #{key}"
        result = yield

        persist_cache_put(key,result)
        result
      else
        long_key="PersistantCacheCache/"+key
        return short_cache(long_key) do
          puts "#{key} key not in short cache.  checking long cache";
          result=persist_cache_peek(key)

          puts "no result from persistant cache" unless result
          puts "cache is write only" if cache_write_only==true
          unless result && !cache_write_only
            result = yield

            persist_cache_put(key,result)
          end
          result
        end
      end
    end
    def short_cache_put(key,value)
      @@cache_me_cache ||= {}
      @@cache_me_cache[key ]
    end
    def short_cache(key,force_refresh=false)
      result = nil
      
      @@cache_me_cache ||= {}
      if  @@cache_me_cache.has_key?(key) && !cache_write_only && !force_refresh
        result=@@cache_me_cache[key]
      else
        result =  @@cache_me_cache[key] = yield
      end

      result
    end

    def clear_short_cache(key=nil)
      @@cache_me_cache={}
    end
  end
end
