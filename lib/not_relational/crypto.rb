require "openssl"
require "base64"
module NotRelational
  class Crypto

    attr_reader :password
    attr_reader :salt
    def initialize(options={})
      @cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")

      @password=options[:password] || "hello"#@cipher.random_password()
      
      @salt=options[:salt] || OpenSSL::Random::random_bytes(8)
      

    end


    def encrypt(text)


      @cipher.encrypt
      @cipher.pkcs5_keyivgen(@password, @salt)

      e = @cipher.update(text)
      e << @cipher.final()
      Base64.encode64(e)#.chomp

    end

    def decrypt(text)
      x=Base64.decode64(text)
      @cipher.decrypt()
      @cipher.pkcs5_keyivgen(@password, @salt)
      d = @cipher.update(x)
      d << @cipher.final()
      return  d
    end
  end
end
