require 'memcache'
require File.dirname(__FILE__) +"/s3.rb"
require File.dirname(__FILE__) +"/query_string_auth_generator.rb"


module NotRelational
  
class Storage
    
  @conn=nil
  @cache=nil
  @memcache_servers=nil
  @aws_key_id = nil
  @aws_secret_key = nil
  attr_accessor :tokens
  attr_accessor :memory_only
  attr_accessor :fail_fast
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
    @logger ||= Logger.new(STDOUT)
    @logger.level = Logger::WARN

    if @memcache_servers and @memcache_servers.length>0
     @cache= MemCache.new @memcache_servers, :namespace => 'my_namespace'
    end
  end
  
  def real_s3
    if self.memory_only
      raise "this is a memcache only storage.  there is no s3"
    end
    unless @conn
      @conn = S3::AWSAuthConnection.new(@aws_key_id, @aws_secret_key,@tokens,false)
    end 
    return @conn
  end
   def real_s3_query_auth
    unless @query_conn
      @query_conn = S3::QueryStringAuthGenerator.new(@aws_key_id, @aws_secret_key,@tokens,false,S3::DEFAULT_HOST, 80,S3::CallingFormat::SUBDOMAIN)
    end 
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

      rescue=> e

                 s= "#{e.message}\n#{e.backtrace}"
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
x=nil
    4.times do |i|
      begin
      x= real_s3.put(bucket,key,S3::S3Object.new(object),attributes)
      

     break
      rescue =>e
        raise e if self.fail_fast
                 s= "#{e.message}\n#{e.backtrace}"
        @logger.error(s)
        @logger.info "retrying s3 put #{i.to_s}"
        sleep(i*i)
        #try again
      end
    end
    if x.http_response.code!="200"
        @logger.error(x.inspect.http_reponse)
         raise "bucket #{bucket} key #{key} response #{x.http_response.code}"
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
    real_s3.delete(bucket,key)
    
  end
  def get(bucket,key)
    value   =nil
    if@cache
      begin
        value=@cache[encode_key(bucket,key)]
      rescue=>e
                   s= "#{e.message}"

        puts("error on  /#{bucket}/#{key} from cache.\n#{s}\n")
      end
    end
       
    if !value
     value=real_s3_get(bucket,key)
      if @cache
        begin
          @cache[encode_key(bucket,key)]=value
        rescue
          #might be too large or memcache might be down
        end
            
      end
    
    end
    return value 
    
  end
  def put(bucket,key,object,attributes={})

    real_s3_put(bucket,key,object,attributes)
    
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

          puts("ERROR when putting /#{bucket}/#{key}into  cache.\n#{s}\n-----------------------\n")
          #TODO try to whack any old value
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
  end


  def clear()
    raise "clear is not implemented for s3 storage.  Did you mean to use MemoryStorage?"
  end
end

end