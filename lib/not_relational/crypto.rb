require "openssl"
 
module NotRelational
  class Crypto

    attr_reader :key
    attr_reader :iv
    def initialize(options={})
      @cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")

      @key=options[:cipher_key] if options.has_key?(:cipher_key)
      @iv=options[:cipher_iv] if options.has_key?(:cipher_iv)

      unless @key
        key_dir=options[:key_dir] if options.has_key?(:key_dir)
        key_dir ||="/tmp"
    
        if File.exists?(key_dir+'/.cipher_key')
          @key=File.open(key_dir+'/.cipher_key').read
        else
          @key =  @cipher.random_key()
          File.open(key_dir+"/.cipher_key",'w').write(@key)
        end
      end


      unless @iv
        if File.exists?(key_dir+'/.cipher_iv')
          @iv=File.open(key_dir+'/.cipher_iv').read
        else
          @iv =  @cipher.random_iv()
          File.open(key_dir+"/.cipher_iv",'w').write(@iv)
        end
      end
    end

    def encrypt(text)

      @cipher.encrypt(@key,@iv)
      @cipher.key=@key
      @cipher.iv = @iv
      e = @cipher.update(text)
      e << @cipher.final()
      Base64.encode64(e)#.chomp

    end

    def decrypt(text)
      x=Base64.decode64(text)
      @cipher.decrypt(@key,@iv)
      @cipher.key = @key
      @cipher.iv = @iv
      d = @cipher.update(x)
      d << @cipher.final()
      return  d
    end
  end
end
