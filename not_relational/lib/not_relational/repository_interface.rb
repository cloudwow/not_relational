# To change this template, choose Tools | Templates
# and open the template in the editor.

module NotRelational
  class BerkeleyRepository
    def initialize(
        domain_name= nil,
        clob_bucket= nil,
        aws_key_id= nil,
        aws_secret_key= nil,
        memcache_servers = nil ,
        dummy=nil,
        append_table_to_domain=nil,
        options={}
      )

    end
    def pause
    end

    def clear_session_cache

    end
def save(table_name, primary_key, attributes,index_descriptions)
end
 def save_into_index(table_name,record,index_name,index_value)

  end

 def retrieve_from_index(table_name,index_name,index_value)
 end

  def query_ids(table_name,attribute_descriptions,options)

  end

     def query(table_name,attribute_descriptions,options)
     end
     def find_one(table_name, primary_key,attribute_descriptions)#, non_clob_attribute_names, clob_attribute_names)
    end
    def get_clob(table_name,primary_key,clob_name)
    end
    def destroy(table_name, primary_key)
    end


end
end