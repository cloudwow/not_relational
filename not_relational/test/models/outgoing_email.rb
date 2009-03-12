require 'digest/sha1'
require "uri"

require "model/domain_model.rb"
class OutgoingEmail < DomainModel
    
  property :id,:string,:is_primary_key=>true
 property :group_invite_id,:string
 
  property :to_address      ,        :string    
  property :to_user_login   ,        :string                   
  property :from_address    ,        :string                                 
  property :subject_blurb  ,        :string                                
  property :content_blurb   ,        :string                            
  property :from_name          ,        :string                   
  property :language_id     ,        :string                 
  property :sent_time      ,        :date       
  property :send_attempt_count  , :unsigned_integer             
  property :last_send_attempt_time ,        :date                      
 property :blurb_parameters_yaml ,  :clob           
     belongs_to :GroupInvite,:group_invite_id
   def OutgoingEmail.convert_arg_to_outgoing_email(email_arg)
     return email_arg if email_arg.respond_to?(:group_invite_id)       
    OutgoingEmail.find(email_id)
   end
end
