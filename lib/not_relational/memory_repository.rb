module NotRelational

  require File.dirname(__FILE__) +"/memory_storage.rb"

  class MemoryRepository < RepositoryBase
    #these attributes neccesary for repo interface
    attr_accessor :use_cache
    attr_accessor :storage
    attr_reader :query_count
    attr_accessor :storage
    attr_accessor :logger

    #this attribute neccesary for base class

    #these are just internal
    attr_accessor :records
    attr_accessor :indexes
    attr_accessor :reverse_indexes
    def initialize(
                   domain_name= nil,
                   blob_bucket= "",
                   aws_key_id= nil,
                   aws_secret_key= nil,
                   memcache_servers = nil ,
                   dummy=nil,
                   use_seperate_domain_per_model=nil,
                   options={}
                   )
      clear
      self.blob_bucket=blob_bucket || "BLOB_BUCKET"
      

      @logger = options[:logger]
      unless @logger
        @logger = Logger.new(STDERR)
        @logger.level = options[:log_level] || Logger::WARN
      end
    end
    def pause
    end

    def clear_session_cache
      @query_count=0
      @storage.clear_counts if  @storage.respond_to?(:clear_counts)
    end

    def clear
      clear_session_cache
      @records={}
      @indexes={}
      @reverse_indexes={}
      @storage ||=MemoryStorage.new
      @storage.clear
    end
    
    def save(table_name, primary_key, attributes,index_descriptions=nil,repository_id=nil)
      key=repository_id || make_repo_key(table_name,primary_key);
      record=@records[key]
      if !record
        record={}
        @records[key]=record
        
      end
      
      attributes.each do |description,value|
        name=description# 
        name=description.name if description.respond_to?(:name)
        record[name]=value
      end
      record["metadata%table_name"]=table_name
      record["metadata%primary_key"]=key
      remove_from_indices(table_name,primary_key)
      if index_descriptions
        index_descriptions.each do |index_name,index|
          index_value=record[index_name.to_sym]
          save_into_index(table_name, record, index.name, index_value)
        end

      end
      #      puts record.to_yaml
    end


    def save_into_index(table_name,record,index_name,index_value)
      @indexes[table_name]||={}
      @indexes[table_name][index_name]||={}
      index=(@indexes[table_name][index_name][index_value]||=[])
      index.each_index do |i|
        if index[i]["metadata%primary_key"]==record["metadata%primary_key"]
          index[i]=record
          return
        end
      end
      index << record
      @reverse_indexes[table_name]||={}
      @reverse_indexes[table_name][record["metadata%primary_key"]]||=[]
      @reverse_indexes[table_name][record["metadata%primary_key"]] << index
    end


    def retrieve_from_index(table_name,index_name,index_value)
      return [] unless @indexes[table_name]
      return [] unless @indexes[table_name][index_name]
      return @indexes[table_name][index_name][index_value] ||[]
    end


    def query_ids(table_name,attribute_descriptions,options)
      primary_key=nil
      attribute_descriptions.each do |name,desc|
        if desc.is_primary_key
          primary_key= name.to_sym
          break
        end
        
      end
      objects=query(table_name,attribute_descriptions,options)
      result=[]
      objects.each do | o|
        result << o[primary_key]
      end
      result
    end
    
    def query(table_name,attribute_descriptions,options)

      @query_count+=1
      if options[:query]
        raise 'query not supported yet'
      end

      result=[]
      params=nil
      conditions=nil
      params=options[:params] if options.has_key?(:params)
      if options.has_key?(:conditions)

        if options[:conditions].is_a?(Hash)
          params ||= {}
          params.merge! options[:conditions]
        else
          conditions=options[:conditions]
        end
      end

      if options.has_key?(:map)
        params||={}
        keys=options[:map][:keys]
        values=options[:map][:values]
        (0..keys.length-1).each do |i|
          key=keys[i]
          value=values[i]
          params[key]=value
        end

      end

      if @logger.debug?
        msg="memory repository query.\n\ttable: #{table_name}\n "
        msg<< "\tlimit: #{options[:limit]}\n" if options.has_key?(:limit)
        if conditions
          msg << "\tconditions:\n"

          conditions.each do |c|
            msg << "\t\t"<< c.to_s << "\n"
          end
        end

        if params
          msg << "\tparams:\n"

          params.each do |key,value|
            msg << "\t\t#{key}: #{value}\n"
          end
        end

        @logger.debug msg
      end

      if options.has_key?(:index)
        result= retrieve_from_index(table_name,options[:index],options[:index_value])
      else
        @records.each do |record_key,record|
          ok=true
          if record["metadata%table_name"]!=table_name
            ok=false
          else
            if params
              
              params.each do |param_key,param_value|

                if param_value==:NOT_NULL
                  if record[param_key]==nil
                    ok=false
                    break
                  end
                elsif param_value==:NULL
                  if record[param_key]!=nil
                    ok=false
                    break
                  end
                elsif param_value.respond_to?(:matches?)

                  if !param_value.matches?(record[param_key])
                    ok=false
                    break
                  end
                elsif !record[param_key] && !param_value
                  # #ok

                elsif record[param_key]!=param_value
                  ok=false
                  break
                end
              end
            end
            if conditions
              
              conditions.each do |condition|

                if !condition.matches?(record)
                  ok=false
                  break
                end
              end
            end
          end
          if ok
            result << record
          end
          
        end
      end
      if options and options[:order_by]
        result.sort! do |a,b|
          
          a_value=a[options[:order_by]]
          b_value=b[options[:order_by]]
          x=0
          if b_value && a_value
            x=b_value <=> a_value
          elsif a_value
            x=-1
          elsif b_value
            x=1
          else
            x=0
          end
          if options[:order] && options[:order]!=:ascending
            x
          else
            -x
          end
        end
      end
      if options[:limit] and result.length>options[:limit]
        result=result[0..options[:limit]-1]
      end
      return result
    end

    def find_one(table_name, primary_key,attribute_descriptions)#,
      #non_clob_attribute_names, clob_attribute_names)
      @query_count+=1

      return @records[make_repo_key(table_name,primary_key)]
    end
    
    def get_text(table_name,primary_key,clob_name,repository_id=nil)

      #      return
      #      @storage.get("",make_storage_key(table_name,repository_key,clob_name))
      record= @records[make_repo_key(table_name,primary_key)]
      return record[clob_name] if record
      return nil
      
    end

    def destroy(table_name, primary_key,repository_id=nil)
      @query_count+=1

      key=repository_id || make_repo_key(table_name,primary_key);
      
      if @records.has_key?(key)
        @records.delete(key)
      end
      remove_from_indices(table_name,primary_key)
    end

    def remove_from_indices(table_name,primary_key)
      key=make_repo_key(table_name,primary_key);
      if @reverse_indexes[table_name]
        indicies=@reverse_indexes[table_name][key]
        if indicies
          indicies.each do |index|
            index.each do |record|
              if record["metadata%primary_key"]==key
                index.delete(record)
                break
              end
            end
          end
          @reverse_indexes[table_name].delete(key)
        end
      end

    end

    private

    def flatten_key(key)
      if key.is_a?( Array)
        flattened_key=""
        key.each do |key_part|
          flattened_key << CGI.escape(key_part.to_s)+"/"
        end
        return flattened_key[0..-2]
      else
        return CGI.escape(key.to_s)
      end
    end

    def make_repo_key(table_name,primary_key)

      primary_key=flatten_key(primary_key)
      return "cached_objects/#{table_name}/#{primary_key}"
    end

    def make_storage_key(table_name,primary_key,clob_name)
      return "clobs/#{table_name}/#{flatten_key(primary_key)}/#{clob_name}"
    end

  end

end
