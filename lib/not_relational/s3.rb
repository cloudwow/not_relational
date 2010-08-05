# #!/usr/bin/env ruby

require 'base64'
require 'cgi'
require 'openssl'
require 'digest/sha1'
require 'net/https'
require 'rexml/document'
require 'time'
module NotRelational

  # this wasn't added until v 1.8.3
  if (RUBY_VERSION < '1.8.3')
    class Net::HTTP::Delete < Net::HTTPRequest
      METHOD = 'DELETE'
      REQUEST_HAS_BODY = false
      RESPONSE_HAS_BODY = true
    end
  end
  # appropriate authentication query string parameters, which could be used in
  # another tool (such as your web browser for GETs).
  module S3
    unless const_defined?('DEFAULT_HOST')
      DEFAULT_HOST = 's3.amazonaws.com'
      PORTS_BY_SECURITY = { true => 443, false => 80 }
      METADATA_PREFIX = 'x-amz-meta-'
      AMAZON_HEADER_PREFIX = 'x-amz-'
      AMAZON_TOKEN_HEADER_PREFIX = "x-amz-security-token"
    end
    # builds the canonical string for signing.
    def S3.canonical_string(method, bucket="", path="", path_args={}, headers={}, expires=nil)
      interesting_headers = {}
      headers.each do |key, value|
        lk = key.downcase
        if (lk == 'content-md5' or
            lk == 'content-type' or
            lk == 'date' or
            lk =~ /^#{AMAZON_HEADER_PREFIX}/o)
          interesting_headers[lk] = value.to_s.strip
        end
      end

      # these fields get empty strings if they don't exist.
      interesting_headers['content-type'] ||= ''
      interesting_headers['content-md5'] ||= ''

      # just in case someone used this.  it's not necessary in this lib.
      if interesting_headers.has_key? 'x-amz-date'
        interesting_headers['date'] = ''
      end

      # if you're using expires for query string auth, then it trumps date (and
      # x-amz-date)
      if not expires.nil?
        interesting_headers['date'] = expires
      end

      buf = "#{method}\n"
      interesting_headers.sort { |a, b| a[0] <=> b[0] }.each do |key, value|
        if key =~ /^#{AMAZON_HEADER_PREFIX}/o
          buf << "#{key}:#{value}\n"
        else
          buf << "#{value}\n"
        end
      end

      # build the path using the bucket and key
      if not bucket.empty?
        buf << "/#{bucket}"
      end
      # append the key (it might be empty string) append a slash regardless
      buf << "/#{path}"

      # if there is an acl, logging, or torrent parameter add them to the string
      if path_args.has_key?('acl')
        buf << '?acl'
      elsif path_args.has_key?('torrent')
        buf << '?torrent'
      elsif path_args.has_key?('logging')
        buf << '?logging'
      end

      return buf
    end

    # encodes the given string with the aws_secret_access_key, by taking the
    # hmac-sha1 sum, and then base64 encoding it.  optionally, it will also url
    # encode the result of that to protect the string if it's going to be used
    # as a query string parameter.
    def S3.encode(aws_secret_access_key, str, urlencode=false)
      digest = OpenSSL::Digest::Digest.new('sha1')
      b64_hmac =
        Base64.encode64(
                        OpenSSL::HMAC.digest(digest, aws_secret_access_key, str)).strip

      if urlencode
        return CGI::escape(b64_hmac)
      else
        return b64_hmac
      end
    end

    # build the path_argument string
    def S3.path_args_hash_to_string(path_args={})
      arg_string = ''
      path_args.each { |k, v|
        arg_string << k
        if not v.nil?
          arg_string << "=#{CGI::escape(v)}"
        end
        arg_string << '&'
      }
      return arg_string
    end


    # uses Net::HTTP to interface with S3.  note that this interface should only
    # be used for smaller objects, as it does not stream the data.  if you were
    # to download a 1gb file, it would require 1gb of memory.  also, this class
    # creates a new http connection each time.  it would be greatly improved
    # with some connection pooling.
    class AWSAuthConnection
      attr_accessor :calling_format

      def initialize(aws_access_key_id,
                     aws_secret_access_key,
                     tokens=Array.new,
                     is_secure=true,
                     server=DEFAULT_HOST,
                     port=PORTS_BY_SECURITY[is_secure],
                     calling_format=CallingFormat::REGULAR)
        @aws_access_key_id = aws_access_key_id
        @aws_secret_access_key = aws_secret_access_key
        @server = server
        @is_secure = is_secure
        @calling_format = calling_format
        @port = port
        @init_headers = {}
        if tokens && !tokens.empty?
          @init_headers[AMAZON_TOKEN_HEADER_PREFIX] = tokens.join(',')
        end
      end

      def create_bucket(bucket, headers={})
        return Response.new(make_request('PUT', bucket, '', {}, headers))
      end

      # takes options :prefix, :marker, :max_keys, and :delimiter
      def list_bucket(bucket, options={}, headers={})
        path_args = {}
        options.each { |k, v|
          path_args[k] = v.to_s
        }

        return ListBucketResponse.new(make_request('GET', bucket, '', path_args, headers))
      end

      def delete_bucket(bucket, headers={})
        return Response.new(make_request('DELETE', bucket, '', {}, headers))
      end
      def escape_key(key)
        parts=key.split('/')
        result=[]
        parts.each{|part|result<< URI.escape(part, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}
        result.join('/')
      end
      def put(bucket, key, object, headers={})
        
        object = S3Object.new(object) if not object.instance_of? S3Object
        x=make_request('PUT', bucket, escape_key(key), {}, headers, object.data, object.metadata)
        return Response.new(x)

      end
      def copy(source_bucket, source_key, destination_bucket,destination_key, headers={})
        headers['x-amz-copy-source']="#{source_bucket}/#{source_key}"
        headers['x-amz-metadata-directive']="REPLACE "
        return GetResponse.new(make_request('PUT', destination_bucket, CGI::escape(destination_key),{}, headers))
      end

      def get_head(bucket, key, headers={})
        return GetResponse.new(make_request('HEAD',bucket, CGI::escape(key),{}, headers))
      end
      def get_content_type(bucket, key, headers={})
        response= get_head(bucket, key, headers)
        if response.http_response.code=='404'
          return nil

        elsif response.http_response.code=='200'
          return response.http_response.header.content_type
        end
        raise response.http_response.code
      end


      def get(bucket, key, headers={})
        return GetResponse.new(make_request('GET', bucket, CGI::escape(key), {}, headers))
      end

      def delete(bucket, key, headers={})
        return Response.new(make_request('DELETE', bucket, CGI::escape(key), {}, headers))
      end

      def get_bucket_logging(bucket, headers={})
        return GetResponse.new(make_request('GET', bucket, '', {'logging' => nil}, headers))
      end

      def put_bucket_logging(bucket, logging_xml_doc, headers={})
        return Response.new(make_request('PUT', bucket, '', {'logging' => nil}, headers, logging_xml_doc))
      end

      def get_bucket_acl(bucket, headers={})
        return get_acl(bucket, '', headers)
      end

      # returns an xml document representing the access control list. this could
      # be parsed into an object.
      def get_acl(bucket, key, headers={})
        return GetResponse.new(make_request('GET', bucket, CGI::escape(key), {'acl' => nil}, headers))
      end

      def put_bucket_acl(bucket, acl_xml_doc, headers={})
        return put_acl(bucket, '', acl_xml_doc, headers)
      end

      # sets the access control policy for the given resource.  acl_xml_doc must
      # be a string in the acl xml format.
      def put_acl(bucket, key, acl_xml_doc, headers={})
        return Response.new(
                            make_request('PUT', bucket, CGI::escape(key), {'acl' => nil}, headers, acl_xml_doc, {})
                            )
      end

      def list_all_my_buckets(headers={})
        return ListAllMyBucketsResponse.new(make_request('GET', '', '', {}, headers))
      end

      private
      def make_request(method, bucket='', key='', path_args={}, headers={}, data='', metadata={})

        # build the domain based on the calling format
        server = ''
        if bucket.empty?
          # for a bucketless request (i.e. list all buckets) revert to regular
          # domain case since this operation does not make sense for vanity
          # domains
          server = @server
        elsif @calling_format == CallingFormat::SUBDOMAIN
          server = "#{bucket}.#{@server}"
        elsif @calling_format == CallingFormat::VANITY
          server = bucket
        else
          server = @server
        end

        # build the path based on the calling format
        path = ''
        if (not bucket.empty?) and (@calling_format == CallingFormat::REGULAR)
          path << "/#{bucket}"
        end
        # add the slash after the bucket regardless the key will be appended if
        # it is non-empty
        path << "/#{key}"

        # build the path_argument string add the ? in all cases since signature
        # and credentials follow path args
        path << '?'
        path << S3.path_args_hash_to_string(path_args)

        http = Net::HTTP.new(server, @port)
        http.use_ssl = @is_secure
        http.start do
          req = method_to_request_class(method).new("#{path}")

          set_headers(req, @init_headers)
          set_headers(req, headers)
          set_headers(req, metadata, METADATA_PREFIX)

          set_aws_auth_header(req, @aws_access_key_id, @aws_secret_access_key, bucket, key, path_args)
          if req.request_body_permitted?
            return http.request(req, data)
          else
            return http.request(req)
          end
        end

      end

      def method_to_request_class(method)
        case method
        when 'GET'
          return Net::HTTP::Get
        when 'PUT'
          return Net::HTTP::Put
        when 'DELETE'
          return Net::HTTP::Delete
        when 'HEAD'
          return Net::HTTP::Head
        else
          raise "Unsupported method #{method}"
        end
      end

      # set the Authorization header using AWS signed header authentication
      def set_aws_auth_header(request, aws_access_key_id, aws_secret_access_key, bucket='', key='', path_args={})
        # we want to fix the date here if it's not already been done.
        request['Date'] ||= Time.now.httpdate

        # ruby will automatically add a random content-type on some verbs, so
        # here we add a dummy one to 'suppress' it.  change this logic if having
        # an empty content-type header becomes semantically meaningful for any
        # other verb.
        request['Content-Type'] ||= ''

        canonical_string =
          S3.canonical_string(request.method, bucket, key, path_args, request.to_hash, nil)
        encoded_canonical = S3.encode(aws_secret_access_key, canonical_string)

        request['Authorization'] = "AWS #{aws_access_key_id}:#{encoded_canonical}"
      end

      def set_headers(request, headers, prefix='')
        headers.each do |key, value|
          request[prefix + key] = value
        end
      end
    end



    class S3Object
      attr_accessor :data
      attr_accessor :metadata
      def initialize(data, metadata={})
        @data, @metadata = data, metadata
      end
    end

    # class for storing calling format constants
    module CallingFormat
      unless const_defined?('VANITY')
        REGULAR   = 0 # http://s3.amazonaws.com/bucket/key
        SUBDOMAIN = 1 # http://bucket.s3.amazonaws.com/key
        VANITY    = 2  # http://<vanity_domain>/key  -- vanity_domain resolves to s3.amazonaws.com
      end
      # build the url based on the calling format, and bucket
      def CallingFormat.build_url_base(protocol, server, port, bucket, format)
        build_url_base = "#{protocol}://"
        if bucket.empty?
          build_url_base << "#{server}:#{port}"
        elsif format == SUBDOMAIN
          build_url_base << "#{bucket}.#{server}:#{port}"
        elsif format == VANITY
          build_url_base << "#{bucket}:#{port}"
        else
          build_url_base << "#{server}:#{port}/#{bucket}"
        end
        return build_url_base
      end
    end

    class Owner
      attr_accessor :id
      attr_accessor :display_name
    end

    class ListEntry
      attr_accessor :key
      attr_accessor :last_modified
      attr_accessor :etag
      attr_accessor :size
      attr_accessor :storage_class
      attr_accessor :owner
    end

    class ListProperties
      attr_accessor :name
      attr_accessor :prefix
      attr_accessor :marker
      attr_accessor :max_keys
      attr_accessor :delimiter
      attr_accessor :is_truncated
      attr_accessor :next_marker
    end

    class CommonPrefixEntry
      attr_accessor :prefix
    end

    # Parses the list bucket output into a list of ListEntry objects, and a list
    # of CommonPrefixEntry objects if applicable.
    class ListBucketParser
      attr_reader :properties
      attr_reader :entries
      attr_reader :common_prefixes

      def initialize
        reset
      end

      def tag_start(name, attributes)
        if name == 'ListBucketResult'
          @properties = ListProperties.new
        elsif name == 'Contents'
          @curr_entry = ListEntry.new
        elsif name == 'Owner'
          @curr_entry.owner = Owner.new
        elsif name == 'CommonPrefixes'
          @common_prefix_entry = CommonPrefixEntry.new
        end
      end

      # we have one, add him to the entries list
      def tag_end(name)
        # this prefix is the one we echo back from the request this prefix is
        # the one we echo back from the request
        if name == 'Name'
          @properties.name = @curr_text
        elsif name == 'Prefix' and @is_echoed_prefix
          @properties.prefix = @curr_text
          @is_echoed_prefix = nil
        elsif name == 'Marker'
          @properties.marker = @curr_text
        elsif name == 'MaxKeys'
          @properties.max_keys = @curr_text.to_i
        elsif name == 'Delimiter'
          @properties.delimiter = @curr_text
        elsif name == 'IsTruncated'
          @properties.is_truncated = @curr_text == 'true'
        elsif name == 'NextMarker'
          @properties.next_marker = @curr_text
        elsif name == 'Contents'
          @entries << @curr_entry
        elsif name == 'Key'
          @curr_entry.key = @curr_text
        elsif name == 'LastModified'
          @curr_entry.last_modified = @curr_text
        elsif name == 'ETag'
          @curr_entry.etag = @curr_text
        elsif name == 'Size'
          @curr_entry.size = @curr_text.to_i
        elsif name == 'StorageClass'
          @curr_entry.storage_class = @curr_text
        elsif name == 'ID'
          @curr_entry.owner.id = @curr_text
        elsif name == 'DisplayName'
          @curr_entry.owner.display_name = @curr_text
        elsif name == 'CommonPrefixes'
          @common_prefixes << @common_prefix_entry
        elsif name == 'Prefix'
          # this is the common prefix for keys that match up to the delimiter
          @common_prefix_entry.prefix = @curr_text
        end
        @curr_text = ''
      end

      def text(text)
        @curr_text += text
      end

      def xmldecl(version, encoding, standalone)
        # ignore
      end

      # get ready for another parse
      def reset
        @is_echoed_prefix = true;
        @entries = []
        @curr_entry = nil
        @common_prefixes = []
        @common_prefix_entry = nil
        @curr_text = ''
      end
    end

    class Bucket
      attr_accessor :name
      attr_accessor :creation_date
    end

    class ListAllMyBucketsParser
      attr_reader :entries

      def initialize
        reset
      end

      def tag_start(name, attributes)
        if name == 'Bucket'
          @curr_bucket = Bucket.new
        end
      end

      # we have one, add him to the entries list
      def tag_end(name)
        if name == 'Bucket'
          @entries << @curr_bucket
        elsif name == 'Name'
          @curr_bucket.name = @curr_text
        elsif name == 'CreationDate'
          @curr_bucket.creation_date = @curr_text
        end
        @curr_text = ''
      end

      def text(text)
        @curr_text += text
      end

      def xmldecl(version, encoding, standalone)
        # ignore
      end

      # get ready for another parse
      def reset
        @entries = []
        @owner = nil
        @curr_bucket = nil
        @curr_text = ''
      end
    end

    class Response
      attr_reader :http_response
      def initialize(response)
        @http_response = response
      end
    end

    class GetResponse < Response
      attr_reader :object
      def initialize(response)
        super(response)
        metadata = get_aws_metadata(response)
        data = response.body
        @object = S3Object.new(data, metadata)
      end

      # parses the request headers and pulls out the s3 metadata into a hash
      def get_aws_metadata(response)
        metadata = {}
        response.each do |key, value|
          if key =~ /^#{METADATA_PREFIX}(.*)$/oi
            metadata[$1] = value
          end
        end
        return metadata
      end
    end

    class ListBucketResponse < Response
      attr_reader :properties
      attr_reader :entries
      attr_reader :common_prefix_entries

      def initialize(response)
        super(response)
        if response.is_a? Net::HTTPSuccess
          parser = ListBucketParser.new
          REXML::Document.parse_stream(response.body, parser)
          @properties = parser.properties
          @entries = parser.entries
          @common_prefix_entries = parser.common_prefixes
        else
          @entries = []
        end
      end
    end

    class ListAllMyBucketsResponse < Response
      attr_reader :entries
      def initialize(response)
        super(response)
        if response.is_a? Net::HTTPSuccess
          parser = ListAllMyBucketsParser.new
          REXML::Document.parse_stream(response.body, parser)
          @entries = parser.entries
        else
          @entries = []
        end
      end
    end
  end
end
