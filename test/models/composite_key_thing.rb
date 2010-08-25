class CompositeKeyThing < NotRelational::DomainModel
  
  property :name,:string,:is_primary_key=>true
  property :is_good,:bool,:is_primary_key=>true
  property :the_time , :date,:is_primary_key=>true
  property :stuff
end


class CompositeKeyThing2  < NotRelational::DomainModel

  property :social_score    ,         :float   , :default_value => 0.0
  property :vote_sum        ,         :float, :default_value => 0.0

  property :site_id,:string,:is_primary_key => true
  property :product_id,:string,:is_primary_key => true
  property :stuff

  property :asin,:string
  property :url,:string
  property :title,:string
  property :snippet,:string
  property :creation_time,:date
  property :author,:string
  property :submitter_login,:string
  property :comment_count, :integer, :default_value => 0
  property :medium_image_url,:string
  property :medium_image_width,:integer
  property :medium_image_height,:integer

  
  belongs_to :Product
  belongs_to :Site

  has_many :ProductRating,:without_prefix

  index :site_id_and_url,[:site_id,:url],:unique => true
  index :site_id_and_asin,[:site_id,:asin]

end
