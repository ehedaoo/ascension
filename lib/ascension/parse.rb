module Parse
  def self.reg_word(word,&b)
    Words.instance.reg_word(word,&b)
  end
  def self.reg_ability(word,ability=nil,&b)
    ability ||= b
    Words.instance.reg_word(word) { |side| ability.call(side) }
  end
  
  class Words
    class << self
      fattr(:instance) { new }
    end
    fattr(:words) { {} }
    fattr(:abilities) { {} }
    def reg_word(word,&b)
      words[word.to_s] = b
      words["first_#{word}"] = lambda do |event|
        b.call(event) && event.first
      end
    end
    def reg_ability(word,ability)
      abilities[word.to_s] = ability
    end
  end
  
  class Word
    include FromHash
    attr_accessor :raw
    def self.parsed(ops)
      new(ops)
    end
    fattr(:word_blk) do
      Words.instance.words[raw.to_s] || (raise "no block for #{raw}")
    end
    def occured?(side)
      if word_blk.arity == 1
        side.events.cond?(&word_blk)
      else
        word_blk[side,nil]
      end
    end
  end
  
  module Phrase
    def self.phrase_class(raw)
      a = raw.split(" ")
      h = {"on" => On, "if" => If, "for" => For}
      if a.size == 3
        h[a[1]]
      else
        Basic
      end
    end
    def self.parsed(raw)
      cls = phrase_class(raw)
      cls.new(:raw => raw)
    end
    
    class Base
      include FromHash
      attr_accessor :raw, :category
      fattr(:before_clause_raw) { raw.split(" ").first }
      fattr(:before_clause) do
        before_clause_raw[0..0] == 'o' ? before_clause_raw[1..-1] : before_clause_raw
      end
      fattr(:optional) do
        before_clause_raw[0..0] == 'o'
      end
      fattr(:after_clause) { raw.split(" ").last }
      fattr(:after_word) do
        Word.parsed(:raw => after_clause)
      end
      def trigger; nil; end
      def ability; nil; end
      def mod_card(card)
        card.triggers << trigger.tap { |x| x.optional = optional if x.respond_to?('optional=') } if trigger
        card.abilities << ability.tap { |x| x.optional = optional if x.respond_to?('optional=') } if ability
      end
      
      def add_honor(side)
        side.honor += before_clause.to_i
      end
      def add_power(side)
        side.pool.power += before_clause.to_i
      end
      def draw_cards(side)
        before_clause.to_i.times do
          side.draw_one!
        end
      end
    end
    
    class Basic < Base
      def mod_card(card)
        if category == :runes
          card.runes += before_clause.to_i if before_clause.to_i > 0
        elsif category == :power || category == :add_power
          card.power += before_clause.to_i
        elsif category == :draw_cards
          card.abilities << lambda do |side|
            draw_cards(side)
          end
        elsif category.kind_of?(Class)
          card.abilities << category.new(:optional => optional)
        else
          raise "unknown category #{category}"
        end
      end
    end
    
    class On < Base
      fattr(:trigger) do
        lambda do |event, side|
          if after_word.word_blk[event]
            send(category, side)
          end
        end
      end
    end
    
    class If < Base
      fattr(:ability) do
        lambda do |side|
          if after_word.occured?(side)
            send(category, side)
          end
        end
      end
    end
    
    class For < Base
      fattr(:ability) do
        lambda do |side|
          meth = "#{after_clause}_runes"
          val = side.played.pool.send(meth) + before_clause.to_i
          side.played.pool.send("#{meth}=",val)
        end
      end
    end
  end
  
  class Card
    include FromHash
    def self.input_field(*args)
      attr_accessor *args
    end
    input_field :rune_cost, :honor_given, :power, :runes, :draw
    input_field :banish_center, :banish_hand_discard
    input_field :special_abilities, :realm, :name, :honor, :power_cost
    fattr(:card_class) do
      ::Card::Hero
    end
    def phrase(raw, cat)
      return nil unless raw
      Phrase.parsed(raw).tap { |x| x.category = cat }
    end
    def mod_for_phrases(raw, cat, card)
      return unless raw
      #puts [raw,cat,card_class,name].inspect
      raw.split(",").each do |r|
        phrase(r,cat).mod_card(card)
      end
    end
    fattr(:card) do
      res = card_class.new(:name => name, :realm => realm)
      
      mod_for_phrases(runes, :runes, res)
      mod_for_phrases(honor_given,:add_honor,res)
      mod_for_phrases(power, :add_power, res)
      mod_for_phrases(draw, :draw_cards, res)
      
      mod_for_phrases(banish_center, Ability::BanishCenter, res)
      mod_for_phrases(banish_hand_discard, Ability::BanishHandDiscard, res)
      
      if special_abilities
        word = Word.parsed(:raw => special_abilities)
        res.abilities << word.word_blk
      end
      
      res.power_cost = power_cost.to_i if res.monster?
      res.rune_cost = rune_cost.to_i unless res.monster?
      
      res
    end
  end
  
  class Line
    include FromHash
    attr_accessor :raw
    attr_accessor :realm_short
    fattr(:card_class) do
      h = {'H' => ::Card::Hero, 'C' => ::Card::Construct, 'M' => ::Card::Monster}
      h[raw['card_type']] || (raise 'no class')
    end
    fattr(:realm) do
      h = {'L' => :lifebound, 'M' => :mechana, 'V' => :void, 'E' => :enlightened, 'S' => :monster}
      h[raw['realm_short']] || (raise 'no realm')
    end
    fattr(:parse_card) do
      card = Card.new
      %w(card_class realm).each do |f|
        card.send("#{f}=",send(f))
      end
      %w(name rune_cost honor runes power power_cost draw banish_center banish_hand_discard special_abilities).each do |f|
        card.send("#{f}=",raw[f])
      end
      card
    end
    fattr(:cards) do
      raw['count'].to_i.of { parse_card.card! }
    end
  end
  
  class InputFile
    fattr(:raw_lines) do
      require 'fastercsv'
      res = []
      f = File.expand_path(File.dirname(__FILE__)) + "/cards.csv"
      FasterCSV.foreach(f,:headers => true, :row_sep => "\n", :quote_char => '"') do |row|
        h = {}
        row.each do |k,v|
          #puts [k,v].inspect
          k = k.downcase.gsub(' ','_')
          h[k] = v
        end
        res << h if h['name']
      end
      res
    end
    fattr(:lines) do
      raw_lines.map { |x| Line.new(:raw => x) }
    end
    fattr(:cards) do
      lines.map { |x| x.cards }.flatten
    end
  end
    
    
end

Parse.reg_word :lifebound_hero_played do |event|
  event.kind_of?(Event::CardPlayed) && event.card.realm.to_s == 'lifebound' && event.card.kind_of?(Card::Hero)
end

Parse.reg_word :mechana_construct_played do |event|
  event.kind_of?(Event::CardPlayed) && event.card.realm.to_s == 'mechana' && event.card.kind_of?(Card::Construct)
end

Parse.reg_word :center_monster_killed do |event|
  event.kind_of?(Event::MonsterKilled) && event.center
end

Parse.reg_word :two_or_more_constructs do |side,junk|
  side.constructs.size >= 2
end

(2..6).each do |i|
  Parse.reg_ability "kill_monster_#{i}", Ability::KillMonster.new(:max_power => i)
end

(1..10).each do |i|
  Parse.reg_ability "acquire_hero_#{i}", Ability::AcquireHero.new(:max_rune_cost => i)
end

Parse.reg_ability :discard_construct, Ability::DiscardConstruct
Parse.reg_ability :discard_all_but_one_construct, Ability::KeepOneConstruct

Parse.reg_ability :copy_hero, Ability::CopyHero.new

%w(power_or_rune_1 take_opponents_card acquire_center).each do |f|
  Parse.reg_ability f do |*args|
  end
end



