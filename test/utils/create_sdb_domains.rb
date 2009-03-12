$KCODE = 'u'
require 'config/boot.rb'
require 'config/environment.rb'
require "aws_sdb"

log = Logger.new(STDOUT)
log.level = Logger::ERROR

devpay_config = YAML.load(File.open("#{File.dirname(__FILE__) }/config/devpay.yml"))

dev_config = devpay_config['development']
test_config = devpay_config['testing']
prod_config = devpay_config['production']

  def create_domain(domain_name)
   
        $sdb.create_domain(domain_name)
        
        
   end
  
   [
   'Node',
    'Mediaitem',
    'Mediafile',
    'Place',
    'Group'
    
  ].each do |model_name|
    #create_domain(dev_config['domain_name']+"_"+model_name)
    create_domain(test_config['domain_name']+"_"+model_name)
   # create_domain(prod_config['domain_name']+"_"+model_name)
  end
  
#  create_domain(dev_config['domain_name']+"_Image")
#   create_domain(dev_config['domain_name']+"_User")
#   create_domain(dev_config['domain_name']+"_ImageFile")
#    
#  
#  create_domain(prod_config['domain_name']+"_Image")
#   create_domain(prod_config['domain_name']+"_User")
#   create_domain(prod_config['domain_name']+"_ImageFile")
    
  