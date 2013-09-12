require 'rubygems'
require 'spork'



class Array
  def reduce(*args,&b)
    inject(*args,&b)
  end
end

class MMIgnore
  def method_missing(sym,*args,&b)
    self
  end
end

class Object
  def mm_ignore
    MMIgnore.new
  end
end


Spork.prefork do
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
  $LOAD_PATH.unshift(File.dirname(__FILE__))

  require 'rspec'
  require 'rr'
  #require 'choice'
  

  # Requires supporting files with custom matchers and macros, etc,
  # in ./support/ and its subdirectories.
  Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

  RSpec.configure do |config|
    config.mock_with :rr
    #config.filter_run :focus => true
    #config.fail_fast = true
  end
end

Spork.each_run do
  load File.dirname(__FILE__) + "/../lib/ascension.rb"
  #Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| load f}
  Parse.reset!

  def db
    Mongo::Connection.new.db('ascension-test')
  end
  
  class CenterDeck < Cards
    def self.starting
      res = CenterDeck.new
      100.times { res << Card::Hero.standin }
      res
    end
  end


end

def new_game_with_side
  game = Game.new
  side = Side.new(:game => game)
  game.sides << side
  [game,side]
end

def new_game_with_sides
  game = Game.new
  side = Side.new(:game => game)
  game.sides << side
  other = Side.new(:game => game)
  game.sides << other
  [game,side]
end

issues = "
buying something with reactor monk subtracts one too many runes"
