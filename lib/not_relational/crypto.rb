require "openssl"
require "base64"
module NotRelational
  class Crypto

    attr_reader :password
    attr_reader :salt
    def initialize(options={})
      @cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")

      @password=options[:password] || "hello"#@cipher.random_password()

      
      @salt=options[:salt]
      # if @salt && @salt.is_a?(String)
      #   @salt=hex_to_binary(@salt)
      # end
      

    end

    def hex_to_binary
      temp = gsub("\s", "");
      ret = []
      (0...temp.size()/2).each{|index| ret[index] = [temp[index*2, 2]].pack("H2")}
      return ret
    end
    
    def encrypt(text,salt=nil)

      return nil unless text
      return "" if text.empty?

      @cipher.encrypt
      @cipher.pkcs5_keyivgen(@password, salt || @salt) 

      e = @cipher.update(text)
      e << @cipher.final()
      Base64.encode64(e)#.chomp

    end

    def decrypt(text,salt=nil)
      return nil unless text
      return "" if text.empty?
      x=Base64.decode64(text)
      @cipher.decrypt()
      @cipher.pkcs5_keyivgen(@password, salt || @salt)
      d = @cipher.update(x)
      d << @cipher.final()
      return  d
    end
  end
end
