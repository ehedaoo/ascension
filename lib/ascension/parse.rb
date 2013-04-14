module Parse
  def self.reg_word(word,&b)
    Words.instance.reg_word(word,&b)
  end
  def self.reg_ability(word,ability=nil,&b)
    ability ||= b
    Words.instance.reg_word(word,ability)
    #wWords.instance.reg_ability(word,ability)
  end
  def self.cards
    @cards ||= InputFile.new.cards
  end
  def self.reset!
    @card = nil
  end
  def self.get(name)
    res = cards.find { |x| x.name == name }.tap { |x| raise "no card #{name}" unless x }
    raise "invoked_ability" if res.respond_to?(:invoked_ability) && res.invoked_ability
    res.invoked_ability = false if res.respond_to?(:invoked_ability)
    res = res.clone
    res.abilities = res.abilities.map { |x| x.clone }
    res.triggers = res.triggers.map { |x| x.clone }
    res
  end
  
  class Words
    class << self
      fattr(:instance) { new }
    end
    fattr(:words) { {} }
    fattr(:abilities) { {} }
    def reg_word(word,ability=nil,&b)
      b ||= ability
      words[word.to_s] = b
      words["first_#{word}"] = lambda do |event|
        b.call(event) && event.first
      end
      words["first_other_#{word}"] = lambda do |event,card|
        b.call(event) && event.first(:excluding => card)
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
      #ops[:raw] = ops[:raw].gsub("other_side-","")
      new(ops)
    end
    fattr(:modifier) do
      a = raw.split("-")
      a.size > 1 ? a[0] : nil
    end
    fattr(:main) do
      raw.split("-").last
    end
    fattr(:word_blk) do
      raw_block = Words.instance.words[main.to_s] || (raise "no block for #{raw}")
      if modifier == 'othefr_side'
        lambda do |side|
          raw_block[side.other_side]
        end
      else
        raw_block
      end
    end
    def occured?(side)
      #side = side.other_side if modifier == "other_side"
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
      h = {"on" => On, "if" => If, "for" => For, "foreach" => Foreach}
      if a.size == 3
        h[a[1]]
      else
        Basic
      end
    end
    def self.parsed(raw)
      raise "found other side" if raw =~ /other_side/
      cls = phrase_class(raw)
      raise "no phrase class for #{raw.inspect}" unless cls
      cls.new(:raw => raw)
    end
    
    class Base
      include FromHash
      attr_accessor :raw, :category

      fattr(:modifier) do
        a = raw.split("-")
        if a.size > 1
          a.first
        else
          nil
        end
      end
      fattr(:raw_no_modifier) do
        raw.split("-").last
      end

      fattr(:before_clause_raw) do
        raw_no_modifier.split(" ").first 
      end
      fattr(:before_clause) do
        before_clause_raw
        #before_clause_raw[0..0] == 'o' ? before_clause_raw[1..-1] : before_clause_raw
      end
      fattr(:optional) do
        modifier == 'optional'
      end
      fattr(:unite) do
        modifier == "unite"
      end
      fattr(:after_clause) { raw.split(" ").last }
      fattr(:after_word) do
        Word.parsed(:raw => after_clause)
      end
      def trigger; nil; end
      def ability; nil; end

      def abilities_target(card)
        (modifier == "invokable") ? card.invokable_abilities : card.abilities
      end

      def mod_card(card)
        card.triggers << trigger.tap { |x| x.optional = optional if x.respond_to?('optional=') }.clone if trigger

        if ability
          abilities_target(card) << ability.tap { |x| x.optional = optional if x.respond_to?('optional=') }.clone
        end
        #card.invokable_abilities << invokable_ability.tap { |x| x.optional = optional if x.respond_to?('optional=') } if invokable_ability
      end
      
      def add_honor(side,num=before_clause)
        #side.honor += before_clause.to_i
        #side.game.honor

        side.gain_honor num.to_i
      end
      def add_power(side,num=before_clause)
        side.played.pool.power += num.to_i
      end
      def draw_cards(side,num=before_clause)
        num.to_i.times do
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
        elsif category == :add_honor
          #raise "in honor part"
          card.honor_earned = before_clause.to_i
        elsif category == :draw_cards
          abilities_target(card) << lambda do |side|
            draw_cards(side)
          end
        elsif category.kind_of?(Class)
          card.abilities << category.new(:optional => optional, :parent_card => card)
        else
          raise "unknown category #{category}"
        end
      end
    end

    class TriggerProc
      include FromHash
      attr_accessor :event_blk, :phrase, :unite
      def call(event,side)
        event_blk[phrase,event,side]
      end
    end

    class OnceProc
      include FromHash
      attr_accessor :cond, :body, :unite
      fattr(:body_count) { 0 }

      fattr(:traces) { [] }
      def add_trace
        begin
          raise 'foo'
        rescue => exp
          self.traces << exp.backtrace
        end
      end
      def call(*args)
        add_trace

        log = lambda do |str|
          traces.last << str
          puts str if $once_debug
        end

      
        log["once call count #{body_count}"]
        log["traces #{traces.size}"]

        if $once_debug
          str = traces.map { |x| x.join("\n") }.join("\n\n\n")
          File.create "traces.txt",str
        end
        return if body_count > 0
        c = cond[*args]
        log["once cond #{c}"] 
        if c
          log["once body"]
          self.body_count += 1
          body[*args]
        end
      end
      def [](*args)
        call(*args)
      end

      def clone
        add_trace
        raise 'body_count' if body_count > 0
        self.class.new(:cond => cond, :body => body, :unite => unite)
      end
    end

    class On < Base
      fattr(:triggerx) do
        lambda do |event, side|
          if after_word.word_blk[event]
            send(category, side)
          end
        end
      end

      fattr(:triggerx) do
        res = TriggerProc.new(:phrase => self, :unite => unite)
        run_count = 0
        res.event_blk = lambda do |p,event,side|
          if run_count == 0 && p.after_word.word_blk[event]
            run_count += 1
            p.send(p.category, side)
            puts event.card.inspect
          end
        end
        res
      end

      fattr(:triggerx) do
        run_count = 0
        lambda do |event,side|
          if run_count == 0 && after_word.word_blk[event]
            run_count += 1
            send(category, side)
            puts event.card.inspect
          end
        end
      end

      fattr(:trigger) do
        res = OnceProc.new(:unite => unite)
        res.cond = lambda do |event,side|
          after_word.word_blk[event]
        end
        res.body = lambda do |event,side|
          send(category,side)
        end
        res
      end


      fattr(:abilityx) do
        if unite
          lambda do |side|
            side.events.each do |event|
              trigger.call(event,side)
            end
          end
        else
          nil
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
    
    # signifies that the reward is only good FOR a certain thing
    class For < Base
      fattr(:ability) do
        lambda do |side|
          meth = "#{after_clause}_runes"
          val = side.played.pool.send(meth) + before_clause.to_i
          side.played.pool.send("#{meth}=",val)
        end
      end
    end

    class Foreach < Base

      fattr(:ability) do
        #raise "bad" unless after_clause == "type_of_construct"
        #cnt = side.constructs.map { |x| x.realm }.uniq.size
        #Ability::EarnHonor.new(:honor => cnt)

        lambda do |side|
          cnt = after_word.word_blk[side]
          send(category,side,cnt)
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
    input_field :discard_from_hand, :banish_hand, :runes_for_honor
    fattr(:card_class) do
      ::Card::Hero
    end
    def make_parsed_phrase_obj(raw, cat)
      return nil unless raw
      #return nil if raw =~ /foreach/
      Phrase.parsed(raw).tap { |x| x.category = cat }
    end

    # Raw Cell is the text from the csv file for this column
    # 
    # method_name_or_ability_class is one of two things:
    # 1. the symbol for the method to call for this column
    # 2. The Class that represents this ability
    def mod_for_phrases(raw_cell, method_name_or_ability_class, card_to_setup)
      return unless raw_cell
      #puts [raw,cat,card_class,name].inspect
      raw_cell.split(",").each do |raw_cell_part|
        p = make_parsed_phrase_obj(raw_cell_part,method_name_or_ability_class)
        p.mod_card(card_to_setup) if p
      end
    end
    fattr(:card) do
      res = card_class.new(:name => name, :realm => realm)

      #raise "witch #{inspect}" if name == 'Flytrap Witch'

      #raise "#{name} #{honor_given}" if honor_given.to_i > 0
      
      mod_for_phrases(runes, :runes, res)
      mod_for_phrases(honor_given,:add_honor,res)
      mod_for_phrases(power, :add_power, res)
      mod_for_phrases(draw, :draw_cards, res)
      
      mod_for_phrases(banish_hand, Ability::BanishHand, res)
      mod_for_phrases(banish_center, Ability::BanishCenter, res)
      mod_for_phrases(banish_hand_discard, Ability::BanishHandDiscard, res)
      mod_for_phrases(discard_from_hand, Ability::DiscardFromHand, res)
      mod_for_phrases(runes_for_honor, Ability::RunesForHonor, res)
      
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
      %w(name rune_cost honor runes power power_cost draw banish_center banish_hand_discard special_abilities discard_from_hand honor_given banish_hand runes_for_honor).each do |f|
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
      require 'csv'
      res = []
      f = File.expand_path(File.dirname(__FILE__)) + "/cards.csv"
      CSV.foreach(f,:headers => true, :row_sep => "\n", :quote_char => '"') do |row|
        h = {}
        row.each do |k,v|
          #puts [k,v].inspect
          if k.present?
            k = k.downcase.gsub(' ','_')
            h[k] = v
          end
        end
        #raise h.inspect if h['name'] == 'Flytrap Witch'
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

Parse.reg_word :count_of_mechana_constructs do |side,*args|
  side.constructs.select { |x| x.mechana? }.size
end

Parse.reg_word :type_of_construct do |side,*args|
  side.constructs.map { |x| x.realm }.uniq.size
end

(2..6).each do |i|
  Parse.reg_ability "kill_monster_#{i}", Ability::KillMonster.new(:max_power => i)
end

(1..10).each do |i|
  Parse.reg_ability "acquire_hero_#{i}", Ability::AcquireHero.new(:max_rune_cost => i)
end

Parse.reg_ability :discard_construct, Ability::DiscardConstruct
Parse.reg_ability :discard_all_but_one_construct, Ability::KeepOneConstruct.new

Parse.reg_ability :copy_hero, Ability::CopyHero.new

Parse.reg_ability :acquire_center, Ability::AcquireCenter.new

Parse.reg_ability :take_opponents_card, Ability::TakeOpponentsCard.new

%w(power_or_rune_1 take_opponents_casrd acquire_centerx).each do |f|
  Parse.reg_ability f do |*args|
  end
end



