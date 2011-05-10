module NotRelational

  #internal class for repositories
  class IndexDescription < PropertyDescription
    include SdbFormatter
    attr_accessor :columns
    
    
    def initialize(name,columns,is_encrypted=false)
      self.name=name
      self.columns=columns
      self.value_type =:string
      self.is_primary_key=false
      self.is_encrypted=is_encrypted
    end
    
    def format_index_entry(attribute_descriptions,attribute_values)
      result=""
      columns.each do |column|
        if column.respond_to?(:transform)
          result << column.transform(attribute_values[column.source_column] )
        else
          result << attribute_descriptions[column].format_for_sdb(attribute_values[column]).to_s
        end
        result << "&"
      end
      result
    end
    def format_for_sdb(value)
      #don't encrypt because the individual elements are encrypted
      return value
    end
    def keys_match?(h)
      return false unless h.length==columns.length
      columns.each do |c|
        return false unless h.has_key?(c)
      end
      return true
    end
  end
end
