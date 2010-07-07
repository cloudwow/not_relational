require 'digest/sha1'
require "uri"

class Tag < NotRelational::DomainModel
    
  property :id,:string,:is_primary_key=>true
  property :tag_name , :string
  property :mediaitem_id , :string
  property :user_name , :string
  property :group_id , :string
  property :created_time , :date

    index :group_with_media ,[:group_id,NotRelational::IsNullTransform.new(:mediaitem_id)]
   index :group_media_tag_user_name ,[:group_id,:mediaitem_id,:tag_name,:user_name],:unique=>:true
   index :tag_and_user_name ,[:tag_name,:user_name]
   index :group_media_tag ,[:group_id,:mediaitem_id,:tag_name],:unique=>:true
   index :group_and_tag ,[:group_id,:tag_name]
   
   
  belongs_to :Mediaitem,:mediaitem_id,:mediaitem
  
    def Tag.url_for_name(tag_name)
      "/tags/#{URI.escape(tag_name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    end
    def create_group_url(group_name)
      return "#{Group.url_from_name(group_name)}/tag/#{URI.escape( tag, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    end
    def Tag.find_group_media_tags(group_id,how_many=50)
#      Tag.find(:all,:order_by=>"tag_name",
#                :params =>{
#                    :group_with_media=>AttributeRange.new(:greater_than_or_equal_to=>calculate_group_with_media(group_id,""), :less_than_or_equal_to=>calculate_group_with_media(group_id+"z","")   )})
        Tag.find_by_group_with_media(group_id,false,:limit=>how_many)
    end
    def Tag.save_tags(user_name,mediaitem,group_id,tags)
        if mediaitem 
            group_id=mediaitem.group_id
            mediaitem_id=mediaitem.id
        else
            mediaitem_id=nil
        end
        tags.each do |tag_name|
            
            if tag_name and tag_name.length>2
                   
               
                    tag_data=Tag.find_by_group_media_tag_user_name(group_id,mediaitem_id,tag_name,user_name)
                     
                if !tag_data                 
                    
                    tag_data=Tag.new
                    tag_data.tag_name=tag_name
                    tag_data.mediaitem_id=mediaitem_id
                    tag_data.group_id=group_id
                    tag_data.user_name=user_name
                    tag_data.created_time=Time.now.gmtime
                    
                    tag_data.save!
                end
                # generate_tag_page(tag_name)
            end
        end
        
     
    end
   def Tag.parse_tag_input(tags_input)
        tags_input.chomp!
        
        tags_input.gsub!(/[\s]+/,",")
        tags_input.gsub!(/[\,]+/,",")
        tag_strings = tags_input.split(",")
        return tag_strings.collect{|x| x.downcase.gsub(/\W/, '')}
        
    end
    def Tag.save_group_tag_input(group_id,tags)
        if mediaitem
            save_tags(user_name,mediaitem,parse_tag_input(tags))
        end
    end
    
    def Tag.save_tag_input(user_name,mediaitem_id,tags)
        mediaitem=Mediaitem.find(mediaitem_id);
        if mediaitem
            save_tags(user_name,mediaitem,nil,parse_tag_input(tags))
        end
        
    end
end
