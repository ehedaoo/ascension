module Ascension
  class << self
    attr_accessor :db
    def db
      @db ||= Mongo::Connection.new.db('ascension')
    end
  end
end

def db
  Ascension.db
end

class Events
  def fire(event)
    
  end
end

class PendingChoiceError < RuntimeError
end