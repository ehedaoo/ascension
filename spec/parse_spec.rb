require File.dirname(__FILE__) + "/spec_helper"

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
      @parse_card.banish_center = "o1"
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
end

describe 'input file' do
  before do
    @file = Parse::InputFile.new
  end
  it 'smoke' do
    @file.lines.size.should == 48
  end
  it 'smoke2' do
    @file.cards.size.should == 100
  end
end

str = "
on is a trigger
if is a conditional ability
for is a rune type"