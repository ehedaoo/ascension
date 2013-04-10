require File.dirname(__FILE__) + "/spec_helper"

class File
  def self.pp(file,obj)
    require 'pp'

    File.open(file,"w") do |f|
      PP.pp(obj,f)
    end
  end
end

def logging_it(name,&b)
  it(name) do
    Debug.log "starting #{name}"
    begin
      instance_eval(&b)
    ensure
      Debug.log "ending #{name}\n\n"
    end
  end
end


describe 'saving a game' do
  before(:all) do
    Debug.clear!

  end
  after(:all) do
    Debug.log "Game spec over"
  end

  include_context "game setup"

  let(:make_game) do
    eye = Parse.get("The All Seeing Eye")
    Debug.log "Parse eye is #{eye.card_id} invoked_ability #{eye.invoked_ability}"

    Game.collection.remove
    Game.collection.count.should == 0
    side
    #File.pp "game.json",game.to_mongo_
    game.mongo.save!
  end

  let(:saved_game) do
    Game.collection.find_one_object
  end

  let(:saved_side) do
    saved_game.sides.first
  end

  logging_it 'smoke' do
    make_game
    Game.collection.count.should == 1
    Game.collection.find_one_object.sides.first.hand.size.should == 5
  end

  describe "playing eye" do


    let(:cards_to_play) { ['The All Seeing Eye'] }
    let(:eye) { saved_side.constructs.first }

    logging_it 'fresh eye from Parse has invokable ability' do
      make_game
      #Parse.get("The All Seeing Eye").invokable_abilities.size.should == 1
    end

    logging_it 'in constructs' do
      make_game
      saved_side.constructs.size.should == 1
    end

    logging_it 'has invokeable ability' do
      make_game
      eye.invokable_abilities.size.should == 1
      eye.invoked_ability.should == false
      eye.has_invokable_ability.should == true
    end

    logging_it 'works thru save' do
      make_game
      saved_side.hand.size.should == 4
      eye.invoke_abilities(saved_side)
      saved_side.hand.size.should == 5
    end

    logging_it 'saves state through save' do
      make_game
      eye.invoke_abilities(saved_side)
      eye.invoked_ability.should == true

      saved_game.mongo.save!
      Game.collection.count.should == 1
      game = Game.collection.find_one_object
      card = game.sides.first.constructs.first

      card.name.should == eye.name
      card.card_id.should == eye.card_id
      card.invoked_ability.should == true
    end


  end
end