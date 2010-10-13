  module NotRelational
    class Error < RuntimeError ; end




    class ConsistencyError < Error
      def initialize(message="",inner_exception=nil)
        message = "409 expected condition check failed. #{message} "
        super(message)
      end
    end
    
  end
