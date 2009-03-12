module NotRelational


class Reference
    attr_accessor :target_class 
    attr_accessor :primary_key 
    attr_accessor :index 
  def initialize(options={})
      if options.has_key?(:target)
          self.target_class=options[:target].class.name.to_sym
          self.primary_key=options[:target].primary_key
      end
      self.index=-1
      if options.has_key?(:index)
          self.index=options[:index]
      end
  end
  def targets?(item)
      return false unless item 
      self.target_class==item.class.name.to_sym and self.primary_key==item.primary_key
  end
  def get_target
      the_class=Kernel.const_get(self.target_class)
      the_class.find(self.primary_key)
      
  end
end
end