require 'base64'
require 'cgi'
require 'openssl'
require 'digest/sha1'
require 'time'
module NotRelational
  module S3
    # This interface mirrors the AWSAuthConnection class, but instead
    # of performing the operations, this class simply returns a url that can
    # be used to perform the operation with the query string authentication
    # parameters set.
    # PLEASE NOTE - For security reasons, it is HIGHLY RECOMMENDED to avoid
    # using product tokens in signed urls.  Please see the README for 
    # further details.
    class QueryStringAuthGenerator
      attr_accessor :calling_format
      attr_accessor :expires
      attr_accessor :expires_in
      attr_reader :server
      attr_reader :port

      # by default, expire in 1 minute
      unless const_defined?('DEFAULT_EXPIRES_IN')
        DEFAULT_EXPIRES_IN = 60
      end

      def initialize(aws_access_key_id, aws_secret_access_key, tokens=Array.new,
                     is_secure=true, 
                     server=DEFAULT_HOST, port=PORTS_BY_SECURITY[is_secure], 
                     format=CallingFormat::REGULAR)
        @aws_access_key_id = aws_access_key_id
        @aws_secret_access_key = aws_secret_access_key
        @protocol = is_secure ? 'https' : 'http'
        @server = server
        @port = port
        @calling_format = format 
        @tokens = tokens 
        # by default expire
        @expires_in = DEFAULT_EXPIRES_IN
        
        
      end
      def tokens
        @tokens
      end

      # set the expires value to be a fixed time.  the argument can
      # be either a Time object or else seconds since epoch.
      def expires=(value)
        @expires = value
        @expires_in = nil
      end

      # set the expires value to expire at some point in the future
      # relative to when the url is generated.  value is in seconds.
      def expires_in=(value)
        @expires_in = value
        @expires = nil
      end

      def create_bucket(bucket, headers={})
        return generate_url('PUT', bucket, '', {}, headers)
      end

      # takes options :prefix, :marker, :max_keys, and :delimiter
      def list_bucket(bucket, options={}, headers={})
        path_args = {}
        options.each { |k, v|
          path_args[k] = v.to_s
        }
        return generate_url('GET', bucket, '', path_args, headers)
      end

      def delete_bucket(bucket, headers={})
        return generate_url('DELETE', bucket, '', {}, headers)
      end

      # don't really care what object data is.  it's just for conformance with the
      # other interface.  If this doesn't work, check tcpdump to see if the client is
      # putting a Content-Type header on the wire.
      def put(bucket, key, object=nil, headers={})
        object = S3Object.new(object) if not object.instance_of? S3Object
        return generate_url('PUT', bucket, CGI::escape(key), {}, merge_meta(headers, object))
      end

      def get(bucket, key, headers={})
        return generate_url('GET', bucket, CGI::escape(key), {}, headers)
      end

      def delete(bucket, key, headers={})
        return generate_url('DELETE', bucket, CGI::escape(key), {}, headers)
      end

      def get_bucket_logging(bucket, headers={})
        return generate_url('GET', bucket, '', {'logging' => nil}, headers)
      end

      def put_bucket_logging(bucket, logging_xml_doc, headers={})
        return generate_url('PUT', bucket, '', {'logging' => nil}, headers)
      end

      def get_acl(bucket, key='', headers={})
        return generate_url('GET', bucket, CGI::escape(key), {'acl' => nil}, headers)
      end

      def get_bucket_acl(bucket, headers={})
        return get_acl(bucket, '', headers)
      end

      # don't really care what acl_xml_doc is.
      # again, check the wire for Content-Type if this fails.
      def put_acl(bucket, key, acl_xml_doc, headers={})
        return generate_url('PUT', bucket, CGI::escape(key), {'acl' => nil}, headers)
      end

      def put_bucket_acl(bucket, acl_xml_doc, headers={})
        return put_acl(bucket, '', acl_xml_doc, headers)
      end

      def list_all_my_buckets(headers={})
        return generate_url('GET', '', '', {}, headers)
      end


      private
      # generate a url with the appropriate query string authentication
      # parameters set.
      def generate_url(method, bucket="", key="", path_args={}, headers={})
        expires = 0
        if not @expires_in.nil?
          expires = Time.now.to_i + @expires_in
        elsif not @expires.nil?
          expires = @expires
        else
          raise "invalid expires state"
        end
        if @tokens && !@tokens.empty?
          headers[AMAZON_TOKEN_HEADER_PREFIX]=@tokens.join(',')
          path_args[AMAZON_TOKEN_HEADER_PREFIX]=@tokens.join(',')
        end
        canonical_string =
          S3::canonical_string(method, bucket, key, path_args, headers, expires)
        encoded_canonical =
          S3::encode(@aws_secret_access_key, canonical_string)
        
        url = CallingFormat.build_url_base(@protocol, @server, @port, bucket, @calling_format)
        
        path_args["Signature"] = encoded_canonical.to_s
        path_args["Expires"] = expires.to_s
        path_args["AWSAccessKeyId"] = @aws_access_key_id.to_s
        
        arg_string = S3.path_args_hash_to_string(path_args) 

        return "#{url}/#{key}?#{arg_string}"
      end

      def merge_meta(headers, object)
        final_headers = headers.clone
        if not object.nil? and not object.metadata.nil?
          object.metadata.each do |k, v|
            final_headers[METADATA_PREFIX + k] = v
          end
        end
        return final_headers
      end
    end
  end
end
