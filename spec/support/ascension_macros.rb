if true
shared_context "ascension macros" do
  def pool_honor
    0
  end
  def pool_cards
    5
  end
  def side_to_use(ops)
    ops ||= {}
    ops = {ops => true} unless ops.kind_of?(Hash)
    ops[:other_side] ? other_side : side
  end
  class << self
    %w(honor runes power cards).each do |type|
      define_method("adds_#{type}") do |num, ops=nil|
        it "adds #{num} #{type} #{ops.inspect}" do
          #puts "starting adds #{num} #{type} #{ops.inspect}"
          newv = side_to_use(ops).get_value(type)
          old = send("pool_#{type}")
          change = newv - old
          #puts "adds #{num} #{type} #{ops.inspect} | changed from #{old} to #{newv}"
          change.should == num
        end
      end
      define_method("adds_no_#{type}") do |ops=nil|
        send("adds_#{type}",0,ops)
      end

      %w(choose_card play_card).each do |m|
        define_method(m) do |*args|
          before do
            send(m,*args)
          end
        end
      end

      %w(constructs hand).each do |m|
        define_method("has_#{m}") do |*args|
          exp = (args.size > 1) ? args : args.first
          it "has #{m} #{exp.inspect}" do
            act = side.get_value(m)
            if exp.kind_of?(Numeric)
              act = act.size if act.kind_of?(Array) || act.kind_of?(Cards)
            elsif exp.kind_of?(Array)
              exp = exp.sort
              act = act.sort
              if exp.first.kind_of?(String)
                act = act.map { |x| x.name }.sort
              end
            end
            act.should == exp
          end
        end

        define_method("#{m}_includes") do |card|
          it "#{m} includes #{card}" do
            act = side.get_value(m).map { |x| x.name }
            act.should be_include(card)
          end
        end
      end
    end
  end
  def self.has_choice(num=1,ops=nil)
    it "has #{num} choice #{ops.inspect}" do
      side_to_use(ops).choices.size.should == num
      ops ||= {}
      if ops[:choosable_cards]
        side_to_use(ops).choices.first.choosable_cards.size.should == ops[:choosable_cards]
      end
    end
  end
  def self.has_no_choice(ops=nil)
    has_choice(0,ops)
  end
  def self.has_trophy(num=1,ops=nil)
    it "has #{num} trophy #{ops.inspect}" do
      side_to_use(ops).trophies.size.should == num
    end
  end
  def self.has_no_trophy(ops=nil)
    has_trophy 0,ops
  end



  def self.describe_played_trophy(trophy=nil,&b)
    describe("played_trophy") do
      before do
        raise "no trophies" if side.trophies.empty?
        card = side.trophies.first.name
        play_trophy(card)
      end
      instance_eval(&b)
    end
  end
end

def describe_engaged(card,&b)
  describe("Engaged #{card}") do
    include_context "game setup"
    include_context "ascension macros"
    let(:cards_to_engage) { [card] }
    instance_eval(&b)
  end
end

def describe_center(card,&b)
  describe("Appeared in center #{card}") do
    include_context "game setup"
    include_context "ascension macros"
    let(:center_cards) { [card] }
    instance_eval(&b)
  end
end

def describe_played(card,&b)
  describe("Played #{card}") do
    include_context "game setup"
    include_context "ascension macros"
    let(:cards_to_play) { [card] }
    instance_eval(&b)
  end
end

def describe_construct_invoked(card, ops={},&b)
  describe("Invoked construct #{card}") do
    include_context "game setup"
    include_context "ascension macros"
    let(:constructs) do
      [card] + (ops[:constructs]||[])
    end

    before do
      invoke_construct card
    end

    instance_eval(&b)
  end
end

def with_choice(card,*args,&b)
  describe "with choice #{card}" do
    #card = place.find { |x| x.name == card } if place
    choose_card card,*args
    instance_eval(&b)
  end
end
end