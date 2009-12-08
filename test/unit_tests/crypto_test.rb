require 'rubygems'
require 'test/unit'
require File.dirname(__FILE__) +'/../../lib/not_relational/crypto.rb'

module NotRelational

  class CryptoTest < Test::Unit::TestCase

    def CryptoTest.set_up
    end

    def test_new
      target=Crypto.new
      
    end
    def test_encrypt_decrypt
      target=Crypto.new
      x=target.encrypt("abc123")
      actual=target.decrypt(x)
      assert_equal("abc123",actual)
      
    end
    def test_encrypt_decrypt_with_password_and_salt
      target=Crypto.new(:password => "duhduhduh",:salt => "23412333")
      x=target.encrypt("abc123")

      target=Crypto.new(:password => "duhduhduh",:salt => "23412333")
      actual=target.decrypt(x)
      assert_equal("abc123",actual)
      
    end
    def test_decrypt_with_wrong_salt
      target=Crypto.new(:password => "duhduhduh",:salt => "23412333")
      x=target.encrypt("abc123")
      target=Crypto.new(:password => "duhduhduh",:salt => "13412333")
      
      assert_raise(OpenSSL::Cipher::CipherError){
        target.decrypt(x)
      }
    end
    def test_decrypt_with_wrong_password
      target=Crypto.new(:password => "duhduhduh",:salt => "23412333")
      x=target.encrypt("abc123")
      target=Crypto.new(:password => "1uhduhduh",:salt => "23412333")
      
      assert_raise(OpenSSL::Cipher::CipherError){
        target.decrypt(x)
      }
    end
    def test_decrypt_with_saved_password_salt
      target=Crypto.new
      x=target.encrypt("abc123")
      target=Crypto.new(:password => target.password,:salt => target.salt)
      

      actual=target.decrypt(x)
      
      assert_equal("abc123",actual)

    end

  end
end
