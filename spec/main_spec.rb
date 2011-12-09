require File.dirname(__FILE__) + "/spec_helper"

describe 'initial game state' do
  before do
    @game = Game.new
  end
  it 'fills center' do
    @game.center.fill!
    @game.center.size.should == 6
  end
end

describe 'game' do
  it 'smoke' do
    2.should == 2
  end
  def hand; @side.hand; end
  before do
    @game = Game.new
    @side = Side.new(:game => @game)
    @game.sides << @side
    @side.draw_hand!
  end
  it 'hand has 5 cards' do
    @side.hand.size.should == 5
  end
  it 'playing a card adds to pool' do
    @side.play(hand.first)
    @side.played.pool.runes.should == 1
  end
end

describe 'ability' do
  describe 'banish' do
    before do
      @game = Game.new
      @side = Side.new(:game => @game)
      @game.sides << @side
      @game.center.fill!
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @card = @game.center.first
      
      Ability::BanishCenter.new.call(@side)
    end
    it 'should be gone from center' do
      @game.center.should_not be_include(@card)
    end
    it 'should be in void' do
      @game.void.should be_include(@card)
    end
    it 'deck should be one less' do
      @game.deck.size.should == 93
    end
    it 'center should be full' do
      @game.center.size.should == 6
    end
  end
  
  describe 'defeat' do
    before do
      @game = Game.new
      @side = Side.new(:game => @game)
      @game.sides << @side
      @game.deck[-1] = Card::Monster.cultist
      @game.deck[-2] = Card::Monster.cultist
      @game.deck[-2].power_cost = 5
      @game.center.fill!
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @card = @game.center.first
    end
    describe "no constraint" do
      before do
        @choice = Ability::KillMonster.new.call(@side)
      end
      it 'should be gone from center' do
        @game.center.should_not be_include(@card)
      end
      it 'should be in void' do
        @game.void.should be_include(@card)
      end
      it 'deck should be one less' do
        @game.deck.size.should == 93
      end
      it 'center should be full' do
        @game.center.size.should == 6
      end
      it 'should add honor' do
        @side.honor.should == @card.honor_earned
      end
      it 'should have 2 options' do
        @choice.choosable_cards.size.should == 2
      end
    end
    describe "power constraint" do
      before do
        @choice = Ability::KillMonster.new(:max_power => 4).call(@side)
      end
      it 'should have 1 option' do
        @choice.choosable_cards.size.should == 1
      end
    end
  end
  
  describe 'acquire' do
    before do
      @game = Game.new
      @side = Side.new(:game => @game)
      @game.sides << @side
      @game.deck[-1].rune_cost = 5
      @game.center.fill!
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @card = @game.center.first
    end
    describe "no constraint" do
      before do
        @choice = Ability::AcquireHero.new.call(@side)
      end
      it 'should be gone from center' do
        @game.center.should_not be_include(@card)
      end
      it 'should be in void' do
        @side.discard.should be_include(@card)
      end
      it 'deck should be one less' do
        @game.deck.size.should == 93
      end
      it 'center should be full' do
        @game.center.size.should == 6
      end
      it 'should have 6 options' do
        @choice.choosable_cards.size.should == 6
      end
    end
    describe "rune constraint" do
      before do
        @choice = Ability::AcquireHero.new(:max_rune_cost => 4).call(@side)
      end
      it 'should have 5 options' do
        @choice.choosable_cards.size.should == 5
      end
    end
  end
  
  describe 'copy hero' do
    before do
      @game, @side = *new_game_with_side
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @side.played << Card::Hero.apprentice
      @choice = Ability::CopyHero.new.call(@side)
    end
    it 'should add rune' do
      @side.played.pool.runes.should == 2
    end
  end
  
  describe 'discard construct' do
    before do
      @game, @side = *new_game_with_sides
      @other_side = @side.other_side
      @other_side.constructs << Card::Construct.shadow_star
      
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @choice = Ability::DiscardConstruct.new.call(@side)
    end
    it 'should remove construct' do
      @other_side.constructs.size.should == 0
    end
    it 'should add to discard' do
      @other_side.discard.size.should == 1
    end
  end
  
  describe 'keep one construct' do
    before do
      @game, @side = *new_game_with_sides
      @other_side = @side.other_side
      3.times { @other_side.constructs << Card::Construct.shadow_star }
      
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @choice = Ability::KeepOneConstruct.new.call(@side)
    end
    it 'should remove construct' do
      @other_side.constructs.size.should == 1
    end
    it 'should add to discard' do
      @other_side.discard.size.should == 2
    end
  end
  
  describe 'take card from opponents hand' do
    before do
      @game, @side = *new_game_with_sides
      @other_side = @side.other_side
      2.times { @other_side.hand << Card::Hero.apprentice }
      
      stub(Ability::CardChoice).chooser do
        lambda { |c| c.options.first }
      end
      @choice = Ability::TakeOpponentsCard.new.call(@side)
    end
    it 'should remove from opponent' do
      @other_side.hand.size.should == 1
    end
    it 'should add to my hand' do
      @side.hand.size.should == 1
    end
  end
end

describe 'all' do
  before do
    @game = Game.new
    @side = Side.new(:game => @game)
    @game.sides << @side
  end

  describe 'buying cards' do
    before do
      @game.center.fill!
      @side.draw_hand!
    
      @side.hand.play_all!
      @side.played.pool.runes.should == @side.played.map { |x| x.runes }.sum
    
      @card = @game.center.first
      @side.purchase(@card)
    end

    it 'discarded' do
      @side.discard.size.should == 1
    end
    it 'took runes' do
      @side.played.pool.runes.should == @side.played.map { |x| x.runes }.sum - 2
    end
    it 'was replaced' do
      @game.center.should_not be_include(@card)
      @game.center.size.should == 6
      @game.deck.size.should == 93
    end
  end

  describe "finishing a turn" do
    before do
      @game.center.fill!
      @side.draw_hand!
      @side.hand.play_all!
      @side.end_turn!
    end
    it 'should discard when done' do
      @side.discard.size.should == 5
      @side.hand.size.should == 5
      @side.deck.size.should == 0
    end
    it 'pool should clear' do
      @side.played.pool.runes.should == 0
    end
    it 'drawing from empty deck' do
      @side.purchase(@game.center.first)
      @side.end_turn!
      @side.total_cards.should == 11
      @side.discard.size.should == 0
      @side.deck.size.should == 6
    end
  end

  describe 'defeat a monster' do
    before do
      @side.played << Card::Hero.heavy_infantry
      @side.played.pool.power.should == 2
      @side.defeat(Card::Monster.cultist)
    end
    it 'should deplete pool' do
      @side.played.pool.power.should == 0
    end
    it 'should add honor' do
      @side.honor.should == 1
    end
  end
  
  describe 'draw ability' do
    before do
      @side.played << Card::Hero.arha
    end
    it 'should draw to hand' do
      @side.hand.size.should == 1
      @side.deck.size.should == 9
    end
  end
  
  describe "playing a construct" do
    before do
      @side.played << Card::Construct.shadow_star
    end
    it 'moves to constructs' do
      @side.constructs.size.should == 1
      @side.played.size.should == 0
    end
    it 'adds power to pool' do
      @side.played.pool.power.should == 1
    end
  end
  
  describe 'starting turn with constructs' do
    before do
      @side.constructs << Card::Construct.shadow_star
      @side.constructs.apply!
    end
    it 'should add power to pool' do
      @side.played.pool.power.should == 1
    end
  end
  
  describe 'events outer' do
    before do
      @trigger = lambda do |event, side|
        if event.first
          side.honor += 1
        end
      end
      @side.constructs << Card::Construct.new(:triggers => [@trigger])
      
      @side.played << Card::Hero.apprentice
    end
    it 'should add honor' do
      @side.honor.should == 1
    end
  end
  

  
end

describe 'pool' do
  before do
    @pool = Pool.new(:runes => 3, :mechana_runes => 1)
    @mechana_card = Card::Construct.new(:realm => :mechana, :rune_cost => 3)
    @normal_card = Card::Construct.new(:realm => :lifebound, :rune_cost => 3)
    @big_card = Card::Construct.new(:rune_cost => 8)
  end
  describe 'purchase mechana' do
    before do
      @pool.deplete_runes(@mechana_card)
    end
    it 'should use mechana runes' do
      @pool.mechana_runes.should == 0
    end
    it 'should leave std rune' do
      @pool.runes.should == 1
    end
  end
  describe 'purchase normal' do
    before do
      @pool.deplete_runes(@normal_card)
    end
    it 'should leave mechana runes' do
      @pool.mechana_runes.should == 1
    end
    it 'should use all std runes' do
      @pool.runes.should == 0
    end
  end
  describe "can't purchase" do
    it 'should error' do
      lambda { @pool.deplete_runes(@big_card) }.should raise_error
    end
  end
end

describe 'basic events' do
  before do
    @events = Event::Events.new
    @card = Card::Hero.apprentice
    @event = Event::CardPlayed.new(:card => @card)
    @events << @event.clone
    @events << @event.clone
  end
  it 'event 1 should have first marked' do
    @events[0].first.should == true
  end
  it 'event 2 should not have first marked' do
    #puts @events.events.map { |x| x.first }.inspect
    @events[1].first.should == false
  end
end