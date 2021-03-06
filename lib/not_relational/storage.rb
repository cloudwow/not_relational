# encoding: utf-8

require 'memcache'
require File.dirname(__FILE__) +"/s3.rb"
require File.dirname(__FILE__) +"/query_string_auth_generator.rb"


module NotRelational

  #place for storing blobs by key.  typically means S3
  #there is some functionality for memcached as well but that code may be in disprepair
  class Storage
    
    @conn=nil
    @cache=nil
    @memcache_servers=nil
    @aws_key_id = nil
    @aws_secret_key = nil
    @session_cache=nil
    attr_accessor :tokens
    attr_accessor :memory_only
    attr_accessor :fail_fast
    attr_accessor :session_cache
    def initialize( aws_key_id,
                    aws_secret_key,
                    memcache_servers,
                    tokens=[] ,
                    options={})
      @memcache_servers=memcache_servers
      if options.has_key?(:fail_fast)
        self.fail_fast=options[:fail_fast]
      end
      if options.has_key?(:memory_only) and options[:memory_only]
        self.memory_only=true
      else
        @aws_key_id=aws_key_id
        @aws_secret_key=aws_secret_key
        @tokens=tokens

      end
      @logger=options[:logger] if options.has_key?(:logger)
      @logger ||= Logger.new(nil)
      @logger.level = Logger::DEBUG

      if @memcache_servers and @memcache_servers.length>0
        @cache= MemCache.new @memcache_servers, :namespace => 'my_namespace'
      end
    end
    def start_session_cache
      @session_cache=MemoryStorage.new
    end
    def clear_session_cache
      @session_cache=MemoryStorage.new
    end
    def end_session_cache
      @session_cache=nil
    end
    def real_s3
      if self.memory_only
        raise "this is a memcache only storage.  there is no s3"
      end
      unless @conn
        #        @conn = ::S3::AWSAuthConnection.new(@aws_key_id, @aws_secret_key,@tokens,false)
        @conn = ::S3::AWSAuthConnection.new(@aws_key_id, @aws_secret_key,false)
      end 
      return @conn
    end
    def real_s3_query_auth
      @query_conn ||= ::S3::QueryStringAuthGenerator.new(@aws_key_id, @aws_secret_key,false,::S3::DEFAULT_HOST, 80,S3::CallingFormat::SUBDOMAIN)
      return @query_conn
    end
    def renew_s3_connection
      @conn=nil
      real_s3
    end
    
    def encode_key(bucket,key)
      val=CGI.escape(bucket+'$@#$%'+key)
      if val.length>250#250 is max key length in memcached
        val=val.hash.to_s
      end
      return val
    end
    def real_s3_get(bucket,key)

      if self.memory_only
        return nil
      end
      4.times do |i|
        begin
          response=real_s3.get(bucket,key)
          if response and response.http_response.code=='404'
            return nil
          end
          if response and response.http_response.code=='200'
            return response.object.data

          end
          
          renew_s3_connection

        rescue Exception => e

          return nil if e.message.index "404"#404=not found
          s= "#{e.message}\n#{e.backtrace}"
          puts "$$$"+s
          @logger.error(s)
          @logger.info "retrying s3 get #{i.to_s}"
          raise e if self.fail_fast
          sleep(i*i)
        end
      end
      return nil
    end
    def create_bucket(bucket,headers={})
      real_s3.create_bucket(bucket,headers)
    end
    def real_s3_put(bucket,key,object,attributes)

      return if self.memory_only
      @logger.info "real s3 put into #{bucket}/#{key}"

      x=nil
      last_error=nil
      4.times do |i|
        begin
          x= real_s3.put(bucket,key,::S3::S3Object.new(object),attributes)
          
          last_error=nil
          break
        rescue =>e
          last_error=e
          raise e if self.fail_fast
          s= "#{e.message}\n#{e.backtrace}"
          @logger.warn(s)
          @logger.info "retrying s3 put #{i.to_s}"
          sleep(i*i)
          #try again
        end
      end
      if x==nil
        raise last_error || "s3.put returned nil"
      end
      if x.http_response.code!="200"
        @logger.error(x.http_response.inspect)
        raise "bucket #{bucket} key #{key} response #{x.http_response.to_yaml}"
      end
      
    end
    def delete(bucket,key)
      if @cache
        begin
          @cache[encode_key(bucket,key)]=nil
        rescue
          #memcache might be down
        end
      end
      @session_cache.delete(bucket,key) if @session_cache
      real_s3.delete(bucket,key)
      
    end
    def get(bucket,key)
      #      puts "storage get: #{key}"
      value   =nil
      value=@session_cache.get(bucket,key) if @session_cache
      return value if value
      if @cache
        begin
          value=@cache[encode_key(bucket,key)]
        rescue=>e
          s= "#{e.message}"

          @logger.error("error on  getting /#{bucket}/#{key} from cache.\n#{s}\n")
        end
      end
      
      unless value
        value=real_s3_get(bucket,key)
        begin

          @cache[encode_key(bucket,key)]=value if @cache
        rescue=>e
          s= "#{e.message}"

          @logger.error("error on  putting /#{bucket}/#{key} into cache.\n#{s}\n")

        end
        
        @logger.debug "------- missed memcached: #{key}"

      else
        @logger.debug "+++++++ got from memcached: #{key}"
      end
      @session_cache.put(bucket,key,value) if @session_cache
      
      return value 
      
    end
    def put(bucket,key,object,attributes={})

      #      puts "Storage put: #{key}, #{object.to_s[0..8]}"
      real_s3_put(bucket,key,object,attributes)
      @session_cache.put(bucket,key,object,attributes) if @session_cache

      #cache in memcache if not media file
      if   memory_only ||
          !attributes ||
          !attributes.has_key?('Content-Type') || 
          (attributes['Content-Type'].index('image')!=0 && attributes['Content-Type'].index('audio')!=0  && attributes['Content-Type'].index('video')!=0   ) 
        if @cache
          begin
            @cache[encode_key(bucket,key)]=object

          rescue=>e
            s= "#{e.message}\n"

            puts("ERROR when putting /#{bucket}/#{key} into  cache.\n#{s}\n-----------------------\n")
            #try to whack old value to avoid stale cache
            puts "attempting to delete stale cache value"
            begin
              @cache[encode_key(bucket,key)]
            rescue=>e2
              s= "#{e.message}\n"
              puts("ERROR when deleting /#{bucket}/#{key} from cache.\n#{s}\n-----------------------\n")

            end
          end
        end
      end

    end
    
    def list_bucket(bucket,prefix=nil) 
      options={}
      options[:prefix]=prefix if prefix
      real_s3.list_bucket(bucket,options)

    end
    def create_public_url(bucket,key) 
      return "http://s3.amazonaws.com/"+bucket+"/"+key
    end
    
    def create_direct_url(bucket,key,time_to_live_minutes=60) 
      real_s3_query_auth.expires_in=time_to_live_minutes*60
      real_s3_query_auth.get(bucket,key)
      

    end
    def create_list_bucket_url(bucket,time_to_live_minutes=60) 
      real_s3_query_auth.expires_in=time_to_live_minutes*60
      real_s3_query_auth.list_bucket(bucket)
      

    end
    def get_content_type(bucket,key)
      return real_s3.get_content_type(bucket,key)

    end
    def copy(old_bucket,old_key,new_bucket,new_key,options)
      real_s3.copy(old_bucket,old_key,new_bucket,new_key,options)
      @session_cache.copy(old_bucket,old_key,new_bucket,new_key,options) if @session_cache

    end


    def clear()
      raise "clear is not implemented for s3 storage.  Did you mean to use MemoryStorage?"
    end
  end

end
