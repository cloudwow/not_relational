$KCODE = 'u'
require "aws_sdb"

log = Logger.new(STDOUT)
log.level = Logger::ERROR
path="#{File.dirname(__FILE__) }/../../config/database.yml"
puts path
devpay_config = YAML.load(File.open(path))

#dev_config = devpay_config['development']
test_config = devpay_config['testing_not_relational']
#prod_config = devpay_config['production']
#$sdb=AwsSdb::Service.new(nil,test_config['aws_key_id'],test_config['aws_secret_key'],"http://sdb.amazonaws.com")
$sdb=AwsSdb::Service.new(
    :access_key_id=>test_config['aws_key_id'],
    :secret_access_key=>test_config['aws_secret_key'],
    :url=>"http://sdb.amazonaws.com",
    :logger=>log)
  def delete_domain(domain_name)
   
        $sdb.delete_domain(domain_name)
        
        
   end
   def create_domain(domain_name)

        $sdb.create_domain(domain_name)


   end
    delete_domain(test_config['base_domain_name'])
  create_domain(test_config['base_domain_name'])
