require File.dirname(__FILE__) + "/spec_helper"

class GameSetup
  include FromHash
  fattr(:center_cards) { [] }
  fattr(:hand_cards) { [] }

  fattr(:game) do
    res = Game.new
    res.sides << Side.new(:game => res)
    center_cards.each { |c| res.center.deck < c }
    res.center.fill!
    res
  end

  fattr(:side) do
    res = game.sides.first
    hand_cards.each { |c| res.deck << c }
    res.draw!
    res
  end
end

shared_context "game setup" do
  before do
    $playing_on_command_line = false
  end

  after do
    $playing_on_command_line = true
  end

  let(:center_cards) { [] }
  let(:hand_cards) { [] }
  let(:cards_to_play) { [] }
  let(:cards_to_engage) { [] }

  let(:pool_power) { 0 }

  let(:game) do
    res = Game.new
    res.sides << Side.new(:game => res)
    res.sides << Side.new(:game => res)
    (center_cards + cards_to_engage).uniq.each { |c| res.deck << Parse.get(c) }
    res.center.fill!
    res
  end

  let(:side) do
    res = game.sides.first
    (hand_cards + cards_to_play).uniq.each { |c| res.deck << Parse.get(c) }
    res.draw_hand!
    res.played.pool.power += pool_power
    cards_to_play.each do |name|
      c = res.hand.find { |x| x.name == name } 
      raise "no card #{name}" unless c
      res.play(c) 
    end

    cards_to_engage.each do |name|
      c = game.center.find { |x| x.name == name }
      raise "no card #{name}" unless c
      res.engage(c)
    end

    res
  end

  let(:other_side) do
    res = game.sides.last
    res.draw_hand!
    res
  end

  let(:choice) do
    raise "wrong number of choices #{side.choices.size}" unless side.choices.size == 1
    side.choices.first
  end

  def choose_card(card,other=false)
    card = Parse.get(card) if card.kind_of?(String)
    (other ? side.other_side.choices.first : choice).execute! card
  end

  def add_to_hand_and_play(name)
    card = Parse.get(name)
    side.hand << card
    side.play(card)
  end

end


describe "share test" do
  include_context "game setup"
  let(:cards_to_play) { ['Reactor Monk'] }
  
  it 'smoke' do
    side.played.pool.runes.should == 2
  end
end

describe "shado test" do
  include_context "game setup"
  let(:cards_to_play) { ['Shade ot Black Watch'] }
  
  it 'smoke' do
    side.played.pool.runes.should == 0
    side.played.pool.power.should == 2
  end

  it 'choices' do
    side.choices.size.should == 1
  end

  it 'choice cards' do
    choice.choosable_cards.size.should == 4
  end

  it 'banish' do
    choose_card side.hand[2]
    side.hand.size.should == 3
  end

  it 'banish' do
    choose_card nil
    side.hand.size.should == 4
  end
end

describe "killing mephit" do
  include_context "game setup"
  let(:center_cards) { ['Mephit'] }
  let(:pool_power) { 10 }
  let(:cards_to_engage) { ['Mephit'] }

  let(:card_to_banish) { game.center[2] }

  it 'smoke' do
    side.played.pool.power.should == 7
    side.choices.size.should == 1
  end

  it 'card is gone' do
    choose_card card_to_banish
    game.void.cards.should == [Parse.get("Mephit"),card_to_banish]
  end
end

describe "playing flytrap witch" do
  include_context "game setup"
  let(:hand_cards) { ["Flytrap Witch"] }
  let(:cards_to_play) { ["Flytrap Witch"] }
  
  let(:witch) { Parse.get("Flytrap Witch") }

  it "has ability" do
    witch.abilities.size.should == 2
  end

  it 'honor pool' do
    side.honor.should == 2
  end
end

describe "pool after reactor monk" do
  include_context "game setup"

  let(:hand_cards) { ["Reactor Monk"] }
  let(:cards_to_play) { ["Reactor Monk"] }

  let(:center_cards) { ["Shadow Star"] }
  let(:cards_to_engage) { ["Shadow Star"] }

  it 'pool runes' do
    side.played.pool.runes.should == 0
  end
end

describe "killing tormented soul (draw monster)" do
  include_context "game setup"

  let(:cards_to_engage) { ["Tormented Soul"] }
  let(:pool_power) { 3 }

  it 'hand size' do
    side.hand.size.should == 6
  end
end

describe "killing wind tyrant" do
  include_context "game setup"

  let(:cards_to_engage) { ["Wind Tyrant"] }
  let(:pool_power) { 5 }

  it 'hand size' do
    side.played.pool.runes.should == 3
    side.honor.should == 3
  end
end

describe "playing arbiter" do
  include_context "game setup"

  let(:hand_cards) { ["Arbiter of the Precipice"] }
  let(:cards_to_play) { ["Arbiter of the Precipice"] }

  it 'has choice' do
    side.choices.size.should == 1
  end

  it 'choice works' do
    choose_card side.hand[0]
    side.hand.size.should == 5
  end

  it "chosing nil errors" do
    lambda { choose_card nil }.should raise_error
  end
end

describe "playing burrower" do
  include_context "game setup"

  let(:cards_to_play) { ["Burrower Mk II"] }

  it 'smoke' do
    side.constructs.size.should == 1
  end

  it 'draws card' do
    side.hand.size.should == 5
  end
end

describe "playing runic lycanthrope" do
  include_context "game setup"

  let(:cards_to_play) { ["Runic Lycanthrope"] }

  it 'smoke' do
    side.played.pool.runes.should == 2
    side.played.pool.power.should == 0
  end

end

describe "playing runic lycanthrope after green" do
  include_context "game setup"

  let(:cards_to_play) { ["Flytrap Witch","Runic Lycanthrope"] }
  it 'smoke' do
    side.played.pool.runes.should == 2
    side.played.pool.power.should == 2
    side.honor.should == 2
  end
end

describe "playing runic lycanthrope after another" do
  include_context "game setup"

  let(:cards_to_play) { ["Runic Lycanthrope"] }
  it 'smoke' do
    add_to_hand_and_play "Runic Lycanthrope"
    side.played.pool.runes.should == 4
    side.played.pool.power.should == 2
    side.honor.should == 0
  end
end

describe "playing 3 runic lycanthropes" do
  include_context "game setup"

  let(:cards_to_play) { ["Runic Lycanthrope"] }
  it 'smoke' do
    add_to_hand_and_play "Runic Lycanthrope"
    add_to_hand_and_play "Runic Lycanthrope"
    side.played.pool.runes.should == 6
    side.played.pool.power.should == 4
    side.honor.should == 0
  end
end

describe "playing avatar golem" do
  include_context "game setup"
  let(:cards_to_play) { ["Rocket Courier X-99","Avatar Golem"] }

  it 'adds honor' do
    side.honor.should == 1
    game.honor.should == 59
  end
end

describe "playing twofold" do
  include_context "game setup"
  let(:cards_to_play) { ["Wolf Shaman","Twofold Askara"] }

  it 'has choice' do
    side.choices.size.should == 1
  end

  it 'choice cards' do
    choice.choosable_cards.size.should == 2
  end

  it 'copies correctly' do
    choose_card side.played[0]
    side.played.pool.runes.should == 2
    side.hand.size.should == 5
  end
end

describe "playing Oziah the Peerless" do
  include_context "game setup"
  let(:cards_to_play) { ["Oziah the Peerless"] }
  let(:center_cards) { ['Wind Tyrant']*3 + ["Avatar ot Fallen"]*3 }

  it 'has choice' do
    side.choices.size.should == 1
  end

  it 'choice cards' do
    choice.choosable_cards.size.should == 2
  end

  it 'chooses' do
    card = game.center.find { |x| x.name == 'Wind Tyrant' }
    card.name.should == 'Wind Tyrant'
    choose_card card
    side.played.pool.runes.should == 3
    side.honor.should == 3
  end
end

describe "playing Avatar" do
  include_context "game setup"
  let(:cards_to_engage) { ["Avatar ot Fallen"] }
  let(:pool_power) { 7 }

  it 'as ability' do
    Parse.get("Avatar ot Fallen").abilities.size.should == 2
  end

  it 'has choice' do
    side.choices.size.should == 1
  end

  it 'choice cards' do
    choice.choosable_cards.size.should == 6
  end

  describe "choose wind tyrant" do
    let(:center_cards) { ['Wind Tyrant'] }

    before do
      choose_card "Wind Tyrant"
      game.void.size.should == 2
    end
    
    it 'gets reward' do
      side.honor.should == 7
    end

    it 'gets runes' do
      side.played.pool.runes.should == 3
    end
  end
end

describe "Xerox Guy" do
  include_context "game setup"
  let(:cards_to_engage) { ["Xeron Duke of Lies"] }
  let(:pool_power) { 10 }

  it 'has choice' do
    side.choices.size.should == 1
  end

  it 'takes card' do
    card = other_side.hand.first
    choose_card card
    other_side.hand.size.should == 4
    side.hand.size.should == 6
  end
end

describe "Sea Tyrant" do
  include_context "game setup"

  before do
    ["Rocket Courier X-99","Burrower Mk II"].each do |card|
      other_side.played << Parse.get(card)
    end
  end

  let(:cards_to_engage) { ["Sea Tyrant"] }

  it 'honor' do
    side.honor.should == 5
  end

  it 'has no choice' do
    side.choices.size.should == 0
  end

  it 'other side has choice' do
    side.other_side.choices.size.should == 1
  end

  it 'stuff' do
    choose_card "Rocket Courier X-99",true
    side.other_side.constructs.map { |x| x.name }.should == ['Rocket Courier X-99']
  end
end

describe "all seeing eye trigger" do
  include_context "game setup"

  let(:cards_to_play) { ['The All Seeing Eye'] }
  let(:eye) { side.constructs.first }

  it 'in constructs' do
    side.constructs.size.should == 1
  end

  it 'check' do
    eye.abilities.size.should == 0
    eye.triggers.size.should == 1
  end
end


describe "ChoiceInstance" do
  before do
    $playing_on_command_line = false
  end

  after do
    $playing_on_command_line = true
  end

  let(:unsaved_shado) do
    Parse.get("Shade ot Black Watch")
  end
  let(:unsaved_game) do
    res = Game.new
    res.sides << Side.new(:game => res)
    res.center.fill!
    res
  end
  let(:unsaved_side) do
    res = unsaved_game.sides.first
    res.deck.cards =  res.deck.sort_by { |x| x.name } + [unsaved_shado]
    res.draw_hand!
    res
  end

  it 'smoke' do
    2.should == 2
  end

  describe "Basic" do
    let(:game) { unsaved_game }
    let(:side) { unsaved_side }

    it "stuff" do
      side.play unsaved_shado
      side.choices.size.should == 1
      side.choices.first.choosable_cards.size.should == 4
    end

    it 'hand cards' do
      side.hand.map { |x| x.name }.should == ["Shade ot Black Watch","Militia","Militia","Apprentice","Apprentice"]
    end

    it 'optional' do
      side.play unsaved_shado
      side.choices.first.optional.should == true
      #raise side.as_json['choices'][0].inspect
      side.as_json['choices'][0]['optional'].should == true
    end
  end

  describe "full" do
    let(:game) do
      unsaved_side.play unsaved_shado
      unsaved_game.mongo.save!
      unsaved_game.mongo.get_fresh
    end
    let(:side) do
      game.sides.first
    end
    let(:choice) do
      side.choices.first
    end
    let(:chosen_card) do
      side.hand.first
    end

    it 'smoke' do
      side.choices.size.should == 1
      choice.choosable_cards.size.should == 4
      side.hand.size.should == 4
    end

    it 'choose' do
      choice.execute! chosen_card
      side.hand.size.should == 3
    end

    describe "with seer" do
      let(:unsaved_shado) do
        Parse.get("Seer of the Forked Path")
      end

      it 'seer abilities' do
        unsaved_shado.abilities.size.should == 2
      end

      it 'smoke' do
        side.choices.size.should == 1
        choice.choosable_cards.size.should == 6
        side.hand.size.should == 5
      end

    end

  
  end

  
end


