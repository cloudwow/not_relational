require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
class Blurb < NotRelational::DomainModel
    
 property :namespace,:string,:is_primary_key=>true
   property :name,:string,:is_primary_key=>true
   property :description , :string  
  
  has_many :BlurbWording,:blurb_id
    
    def Blurb.get(namespace,name)
        Blurb.find([namespace , name])

    end
     def get_wording(language=$language)
         wording=BlurbWording.find([self.name ,self.namespace,language])
           if !wording && language!='en'
            
                return self.get_wording('en')
            
            end
           if !wording
            return  self.name
           end
         return wording.text
     end
     def set_wording(language,text)
        wording=BlurbWording.find([self.name ,self.namespace,language])
         if !wording
            wording=BlurbWording.new
            wording.blurb_name=self.name
            wording.blurb_namespace=self.namespace
            wording.language_id=language
         end
         wording.text=text
         wording.save
         return wording
         
     end
      def Blurb.set_wording(namespace,name,language,text)
         blurb=Blurb.get(namespace,name)
         if !blurb
            blurb=Blurb.new
            blurb.name=name
            blurb.namespace=namespace
            blurb.save!
         end
         blurb.set_wording(language,text)
     end
     
     def Blurb.get_wording(namespace,name,language_id='en',default_value=nil)
       result=BlurbWording.find([name ,namespace,language_id])
      if result!=nil
         return result.text
      end
      if   language_id=='en'
        return default_value || name
      end
     return Blurb.get_wording(namespace,name,'en')
   
     end
   
end
