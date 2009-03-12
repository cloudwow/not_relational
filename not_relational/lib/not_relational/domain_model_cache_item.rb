module NotRelational


class DomainModelCacheItem
    attr_accessor :table_name
    attr_accessor :primary_key
    attr_accessor :non_clob_attributes
  def initialize(table_name,primary_key,non_clob_attributes)
    self.table_name=table_name
    self.primary_key=primary_key
    self.non_clob_attributes=non_clob_attributes
  end
end
end