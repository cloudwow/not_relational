require 'logger'
require 'time'
require 'cgi'
require 'uri'
require 'net/http'
require 'base64'
require 'openssl'
require 'rexml/document'
require 'rexml/xpath'

module AwsSdb
  class Service
     def query_with_attributes(domain, query, max = nil, token = nil)
      params = {
        'Action' => 'QueryWithAttributes',
        'QueryExpression' => query,
        'DomainName' => domain.to_s
      }
      params['NextToken'] =
        token unless token.nil? || token.empty?
      params['MaxNumberOfItems'] =
        max.to_s unless max.nil? || max.to_i == 0
      doc = call(:get, params)
      results = []
      REXML::XPath.each(doc, '//Item') do |item|
        item_attributes={}
         item_name = REXML::XPath.first(item, './Name/text()').to_s
       
        
         REXML::XPath.each(item, "./Attribute") do |attr|
           
            key = REXML::XPath.first(attr, './Name/text()').to_s
            value = REXML::XPath.first(attr, './Value/text()').to_s
            ( item_attributes[key] ||= [] ) << value
        end
         results<<[item_name,item_attributes]
       
      end
      return results, REXML::XPath.first(doc, '//NextToken/text()').to_s
    end
    
    


   
  end
end
