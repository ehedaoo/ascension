require File.dirname(__FILE__) + "/spec_helper"

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

describe 'phrase' do
  before do
    @side = Side.new
    @card = Card::Hero.new(:realm => :lifebound)
    @event = Event::CardPlayed.new(:card => @card)
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
  
  describe 'if' do
    before do
      @side = Side.new
      @card = Card::Hero.new(:realm => :lifebound)
      @event = Event::CardPlayed.new(:card => @card)
      
      @phrase = Parse::Phrase.parsed("1 if lifebound_hero_played")
    end
    describe 'hero played' do
      before do
        @side.events << @event
      end
      it 'should be true' do
        @side.events.should be_cond(:lifebound_hero_played)
      end
    end
    describe 'hero not played' do
      before do
        @side.events << @event
      end
      it 'should be true' do
        @side.events.should_not be_cond(:lifebound_hero_played)
      end
    end
  end
end

str = "
on is a trigger
if is a conditional ability
for is a rune type"