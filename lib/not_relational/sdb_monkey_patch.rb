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
  class InvalidParameterError < RequestError ; end
  class InvalidWSDLVersionError < RequestError ; end
  class InvalidSortExpressionError < RequestError ; end

  class Service

    
    def query_with_attributes(domain, query, max = nil, token = nil,extra_params={})
      full_query="select * from #{domain} "
      if query && !query.empty?
        full_query<< " where #{query}"
      end
      

      if max
        full_query << " limit #{max}"
      end
      params = {
        'Action' => 'Select',
        'SelectExpression' => full_query
      }.merge(extra_params)

      begin
        params['NextToken'] =
          token unless token.nil? || token.empty?
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

      rescue Exception => e
        puts "****************** error during query ************\n#{query}\n**************************************"
        raise e
      end
      
      
    end
    
    def get_attributes(domain, item,extra_params={})
      doc = call(
                 :get,
                 {
                   'Action' => 'GetAttributes',
                   'DomainName' => domain.to_s,
                   'ItemName' => item.to_s
                 }.merge(extra_params)
                 )
      attributes = {}
      REXML::XPath.each(doc, "//Attribute") do |attr|
        key = REXML::XPath.first(attr, './Name/text()').to_s
        value = REXML::XPath.first(attr, './Value/text()').to_s
        ( attributes[key] ||= [] ) << value
      end
      attributes
    end


    def call(method, params)
      params.merge!( {
                       'Version' => '2009-04-15',
                       'SignatureVersion' => '1',
                       'AWSAccessKeyId' => @access_key_id,
                       'Timestamp' => Time.now.gmtime.iso8601
                     }
                     )
      data = ''
      query = []
      params.keys.sort_by { |k| k.upcase }.each do |key|
        data << "#{key}#{params[key].to_s}"
        query << "#{key}=#{CGI::escape(params[key].to_s)}"
      end
      digest = OpenSSL::Digest::Digest.new('sha1')
      hmac = OpenSSL::HMAC.digest(digest, @secret_access_key, data)
      signature = Base64.encode64(hmac).strip
      query << "Signature=#{CGI::escape(signature)}"
      query = query.join('&')
      url = "#{@base_url}?#{query}"
      uri = URI.parse(url)
      @logger.debug("#{url}") if @logger
      response =
        Net::HTTP.new(uri.host, uri.port).send_request(method, uri.request_uri)
      @logger.debug("#{response.code}\n#{response.body}") if @logger
      raise(ConnectionError.new(response)) unless (200..400).include?(
                                                                      response.code.to_i
                                                                      )
      doc = REXML::Document.new(response.body)
      error = doc.get_elements('*/Errors/Error')[0]
      raise(
            Module.class_eval(
                              "AwsSdb::#{error.get_elements('Code')[0].text}Error"
                              ).new(
                                    error.get_elements('Message')[0].text,
                                    doc.get_elements('*/RequestID')[0].text
                                    )
            ) unless error.nil?
      doc
    end


    def put_attributes(domain, item, attributes, replace = true,extra_params = {})
      params = {
        'Action' => 'PutAttributes',
        'DomainName' => domain.to_s,
        'ItemName' => item.to_s
      }.merge(extra_params)
      count = 0
      attributes.each do | key, values |
        ([] << values).flatten.each do |value|
          params["Attribute.#{count}.Name"] = key.to_s
          params["Attribute.#{count}.Value"] = value.to_s
          params["Attribute.#{count}.Replace"] = replace
          count += 1
        end
      end
      call(:put, params)
      nil
    end

  end
end
