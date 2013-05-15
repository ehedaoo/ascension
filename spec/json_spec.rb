require File.dirname(__FILE__) + "/spec_helper"

describe 'card json' do
  let(:card) do
    Card::Construct.new(:name => "Some Card", :invokable_abilities => [14])
  end
  it 'has card id' do
    card.as_json['card_id'].should == card.card_id
  end
  it 'has invokable ability' do
    card.as_json['has_invokable_ability'].should == true
  end

end

describe "game json" do
  include_context "game setup"

  let(:hand_cards) { ['Void Initiate'] }

  it 'image_url' do
    side
    json = game.as_json
    card = json['sides'].first['hand']['cards'].first
    card['name'].should == 'Void Initiate'
    url = card['image_url']
    url.should == 'http://www.nerdtitan.com/wp-content/uploads/2013/01/void-initiate.png'
  end

  it 'image url 2' do
    side
    game.mongo.save!
    g2 = Game.collection.find_objects(:_id => game.mongo_id).to_a.first.as_json
    #raise game.sides.first.hand.map { |x| x.name }.inspect
    card = g2['sides'].first['hand']['cards'].first
    card['name'].should == 'Void Initiate'
    #raise card.inspect
    url = card['image_url']
    url.should == 'http://www.nerdtitan.com/wp-content/uploads/2013/01/void-initiate.png'
  end

  it 'image url 3' do
    Game.reset!
    g2 = Game.collection.find_objects.to_a.first.as_json
    #raise game.sides.first.hand.map { |x| x.name }.inspect
    card = g2['sides'].first['hand']['cards'].first
    #card['name'].should == 'Apprentice'
    #raise card.inspect
    #url = card['image_url']
    #url.should == 'none'
  end
end

describe 'iamges' do
  it 'smoke' do
    #raise ImageMap.cards_without_image.inspect
  end
end