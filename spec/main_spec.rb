require File.dirname(__FILE__) + "/../main.rb"

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
      @side.played.pool.runes.should == 5
    
      @card = @game.center.first
      @side.purchase(@card)
    end

    it 'discarded' do
      @side.discard.size.should == 1
    end
    it 'took runes' do
      @side.played.pool.runes.should == 3
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
  
end