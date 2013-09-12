require File.dirname(__FILE__) + "/spec_helper"

describe "Parse" do
if false
  describe 'word' do
    describe 'first_lifebound_hero_played' do
      before do
        @raw = "first_lifebound_hero_played"
        @word = Parse::Word.parsed(:raw => @raw)
      end
      it 'should be first' do
        @word.should be_first
      end
      it 'should have realm' do
        @word.realm.should == 'lifebound'
      end
      it 'should have type' do
        @word.type.should == "hero_played"
      end
    end
    describe 'lifebound_hero_played' do
      before do
        @raw = "lifebound_hero_played"
        @word = Parse::Word.parsed(:raw => @raw)
      end
      it 'should not be first' do
        @word.should_not be_first
      end
      it 'should have realm' do
        @word.realm.should == 'lifebound'
      end
      it 'should have type' do
        @word.type.should == "hero_played"
      end
    end
  end
end

describe 'split' do
  it 'split' do
    reg = /[,;]/
    "1,2".split(reg).should == %w(1 2)
    "1;2".split(reg).should == %w(1 2)
  end
end

describe 'word' do
  before do
    @side = Side.new
    @card = Card::Hero.new(:realm => :lifebound)
    @event = Event::CardPlayed.new(:card => @card)
    @word = Parse::Word.new(:raw => "lifebound_hero_played")
  end
  it 'should be true' do
    @side.events << @event
    @word.should be_occured(@side)
  end
  it 'should be false' do
    @word.should_not be_occured(@side)
  end
end

describe "of" do
  include_context "game setup"

  let(:raw) { "1 of power" }
  let(:raw_card) { Card::Hero.new(:name => "Test Card") }
  let(:phrase) { Parse::Phrase.parsed(raw) }
  let(:modded_card) do
    phrase.mod_card(raw_card)
    raw_card
  end
  let(:cards_to_play) { [modded_card] }

  it 'should have 1 power' do
    side.played.pool.power.should == 1
  end

  describe "runes" do
    let(:raw) { "1 of runes" }
    it 'should have 1 power' do
      side.played.pool.runes.should == 1
    end
  end

  describe "2 runes" do
    let(:raw) { "2 of runes" }
    it 'should have 1 power' do
      side.played.pool.runes.should == 2
    end
  end
end

describe "and" do
  include_context "game setup"
  include_context "ascension macros"

  let(:raw) { "(1 of power) and (1 of runes)" }
  let(:raw_card) { Card::Hero.new(:name => "Test Card") }
  let(:phrase) { Parse::Phrase.parsed(raw) }
  let(:modded_card) do
    phrase.mod_card(raw_card)
    raw_card
  end
  let(:cards_to_play) { [modded_card] }

  adds_power 1
  adds_runes 1
  has_choice 0
end

if true
describe "and - using 'this' instead of specified type" do
  include_context "game setup"
  include_context "ascension macros"

  let(:raw) { "optional-(1 of this) and (1 of runes)" }
  let(:raw_card) { Card::Hero.new(:name => "Test Card") }
  let(:phrase) { Parse::Phrase.parsed(raw).tap { |x| x.category = category } }
  let(:category) { Ability::BanishHand }
  let(:modded_card) do
    phrase.mod_card(raw_card)
    raw_card
  end
  let(:cards_to_play) { [modded_card] }

  #choose_card "Apprentice"

  adds_power 0
  adds_runes 0
  has_choice

  has_hand 4



  describe "chose apprentice" do
    before do
      card = side.hand.find { |x| x.name == 'Apprentice' }
      choose_card card
    end
    has_hand 3
    adds_runes 1
    has_choice 0
  end

  describe "chose nothing" do
    before do
      choose_card nil
    end
    has_hand 4
    adds_runes 0
    has_choice 0
  end
end
end

if false
describe "and - using 'this' instead of specified type - reward" do
  include_context "game setup"
  include_context "ascension macros"

  let(:raw) { "(1 of this) and (1 of rewardrunes)" }
  let(:raw_card) { Card::Hero.new(:name => "Test Card") }
  let(:phrase) { Parse::Phrase.parsed(raw).tap { |x| x.category = category } }
  let(:category) { Ability::BanishHand }
  let(:modded_card) do
    phrase.mod_card(raw_card)
    raw_card
  end
  let(:cards_to_play) { [modded_card] }

  #choose_card "Apprentice"

  adds_power 0
  adds_runes 0
  has_choice

  has_hand 4
end
end


describe "or" do
  include_context "game setup"

  let(:raw) { "(1 of power) or (1 of runes)" }
  let(:raw_card) { Card::Hero.new(:name => "Test Card") }
  let(:phrase) { Parse::Phrase.parsed(raw) }
  let(:modded_card) do
    phrase.mod_card(raw_card)
    raw_card
  end
  let(:cards_to_play) { [modded_card] }

  it 'should have choice' do
    side.choices.size.should == 1
  end

  it 'choice works' do
    choose_card choice.choosable_cards.first
    side.played.pool.power.should == 1
    side.played.pool.runes.should == 0
  end

  it 'choice works 2' do
    choose_card choice.choosable_cards.last
    side.played.pool.runes.should == 1
    side.played.pool.power.should == 0
  end

  # needs the choices to be named somehow
end

if true
describe "or 2" do
  include_context "game setup"

  let(:raw) { "(3 of runes) or (1 of draw)" }
  let(:raw_card) { Card::Hero.new(:name => "Test Card") }
  let(:phrase) { Parse::Phrase.parsed(raw) }
  let(:modded_card) do
    phrase.mod_card(raw_card)
    raw_card
  end
  let(:cards_to_play) { [modded_card] }
  let(:center_cards) { ["Rocket Courier X-99","Hedron Cannon"] }

  it 'should have choice' do
    side.choices.size.should == 1
  end

  it 'choice works' do
    choose_card choice.choosable_cards.first
    side.played.pool.runes.should == 3
  end

  it 'choice works 2' do
    side.hand.size.should == 4
    choose_card choice.choosable_cards.last
    side.hand.size.should == 5
  end

  # needs the choices to be named somehow
end
end

if true
describe "or 3" do
  include_context "game setup"

  let(:raw) { "(3 of runes) or (1 of acquire_construct)" }
  let(:raw_card) { Card::Hero.new(:name => "Test Card") }
  let(:phrase) { Parse::Phrase.parsed(raw) }
  let(:modded_card) do
    phrase.mod_card(raw_card)
    raw_card
  end
  let(:cards_to_play) { [modded_card] }
  let(:center_cards) { ["Rocket Courier X-99","Hedron Cannon"] }

  it 'should have choice' do
    side.choices.size.should == 1
  end

  it 'choice works' do
    choose_card choice.choosable_cards.first
    side.played.pool.runes.should == 3
  end

  it 'choice works 2' do
    choose_card choice.choosable_cards.last
    side.choices.size.should == 1
    choose_card "Hedron Cannon"
    side.discard.map { |x| x.name }.should == ['Hedron Cannon']
  end

  # needs the choices to be named somehow
end
end

describe 'phrase' do
  before do
    @side = Side.new
    @card = Card::Hero.new(:realm => :lifebound)
    @event = Event::CardPlayed.new(:card => @card, :first => true)
  end
  
  describe 'on' do
    fattr(:phrase) do
      Parse::Phrase.parsed(@raw).tap { |x| x.category = @category }
    end
    before do
      @raw = "1 on first_lifebound_hero_played"
      @category = :add_honor
    end
    it 'execute trigger' do
      phrase.trigger.call(@event, @side)
      @side.honor.should == 1
    end
    it 'execute trigger' do
      @raw = "2 on first_lifebound_hero_played"
      phrase.trigger.call(@event, @side)
      @side.honor.should == 2
    end
    it 'shouldnt run' do
      @card.realm = :mechana
      phrase.trigger.call(@event, @side)
      @side.honor.should == 0
    end
    it 'should add trigger to card' do
      phrase.mod_card(@card)
      @card.triggers.size.should == 1
    end
  end
  if true
    describe 'if' do
      before do
        @side = Side.new
        @card = Card::Hero.new(:realm => :lifebound)
        @event = Event::CardPlayed.new(:card => @card)
      
        @phrase = Parse::Phrase.parsed("1 if lifebound_hero_played").tap { |x| x.category = :add_honor }
      end
      
      it 'foo' do
        @phrase.mod_card(@card)
        @card.abilities.size.should == 1
        
        @side.events << @event
        
        @card.apply_abilities(@side)
        @side.honor.should == 1
      end
    end
  end
  
  describe 'Card' do
    before do
      @side = Side.new
      @first_card = Card::Hero.new(:realm => :lifebound)
      @parse_card = Parse::Card.new(:rune_cost => 2, :honor_given => "1 if lifebound_hero_played", :runes => "1")
    end
    it 'should make card - smoke' do
      @parse_card.card
    end
    it 'card should add honor' do
      @side.played << @first_card
      @side.played << @parse_card.card
      @side.honor.should == 1
    end
    it 'card should not add honor' do
      @side.played << @parse_card.card
      @side.honor.should == 0
    end
    it 'card gives 1 rune' do
      @side.played << @parse_card.card
      @side.played.pool.runes.should == 1
    end
    it 'card gives 1 mech rune' do
      @parse_card.runes = "1 for mechana"
      @side.played << @parse_card.card
      @side.played.pool.mechana_runes.should == 1
    end
    it 'card gives 1 normal, 1 mech rune' do
      @parse_card.runes = "1,1 for mechana"
      @side.played << @parse_card.card
      @side.played.pool.runes.should == 1
      @side.played.pool.mechana_runes.should == 1
    end
    it 'draws 1' do
      @parse_card.draw = "1"
      @side.played << @parse_card.card
      @side.hand.size.should == 1
    end
    it 'draws 1 cond' do
      @parse_card.draw = "1 if two_or_more_constructs"
      @side.played << @parse_card.card
      @side.hand.size.should == 0
    end
    it 'draws 1 cond' do
      @parse_card.draw = "1 if two_or_more_constructs"
      stub(@side.constructs).size { 2 }
      @side.played << @parse_card.card
      @side.hand.size.should == 1
    end
  end
  
  describe 'banish' do
    before do
      @game, @side = *new_game_with_side
      @game.center.fill!
      
      @card = @game.center.first
      
      @parse_card = Parse::Card.new(:banish_center => "1")
    end
    it 'should banish a card' do
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      
      @game.void.size.should == 0
      @parse_card.card.apply_abilities(@side)
      @game.void.size.should == 1
    end
    it 'should not banish a card' do
      @parse_card.banish_center = "optional-1"
      stub(Ability::CardChoice).chooser do
        lambda { |c| nil }
      end
      
      @game.void.size.should == 0
      @parse_card.card.apply_abilities(@side)
      @game.void.size.should == 0
    end
  end
  
  describe 'kill monster' do
    before do
      @game, @side = *new_game_with_side
      @game.center << Card::Monster.cultist
      @parse_card = Parse::Card.new(:special_abilities => "kill_monster_4")
    end
    it 'should add ability' do
      @parse_card.card.abilities.size.should == 1
    end
    it 'ability should kill' do
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @parse_card.card.apply_abilities(@side)
      @side.honor.should == 1
    end
  end

  describe "or" do
    let(:raw) { "abc" }
    fattr(:phrase) do
      Parse::Phrase.parsed(@raw).tap { |x| x.category = @category }
    end
  end
end

describe 'input file' do
  before do
    @file = Parse::InputFile.new
  end
  it 'smoke' do
    #@file.lines.size.should == 53
  end
  it 'smoke2' do
    #@file.cards.size.should == 112
  end
end
end

str = "
on is a trigger
if is a conditional ability
for is a rune type"