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
      
        @phrase = Parse::Phrase.parsed("1 if lifebound_hero_played")
      end
      describe 'hero played' do
        before do
          @side.events << @event
        end
        it 'should be true' do
          @phrase.after_word.should be_occured(@side)
        end
      end
      describe 'hero not played' do
        it 'should be true' do
          @phrase.after_word.should_not be_occured(@side)
        end
      end
    end
  end
end

str = "
on is a trigger
if is a conditional ability
for is a rune type"