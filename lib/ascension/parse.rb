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
    fattr(:main) do
      raise "trophy" if raw.to_s =~ /trophy/
      a = raw.split("-")
      #raise "bad stuff #{raw}" if a.first == 'invokable'
      a.last
    end
    fattr(:modifier) do
      a = raw.split("-")
      if a.size == 1
        nil
      elsif a.first == 'invokable'
        a.first
      else
        nil
        #raise "unknown #{a.inspect}"
      end
    end
    fattr(:word_blk) do
      Words.instance.words[main.to_s] || (raise "no block for #{raw}")
    end
    def occured?(side)
      #side = side.other_side if modifier == "other_side"
      if word_blk.arity == 1
        side.events.cond?(&word_blk)
      else
        word_blk[side,nil]
      end
    end
    def add_ability(card)
      Phrase::Base.abilities_target(card,modifier) << word_blk
    end
  end
  
  module Phrase
    def self.phrase_class(raw)
      a = raw.split(" ")
      h = {"on" => On, "if" => If, "for" => For, "foreach" => Foreach, "of" => Of, "and" => And, "or" => Or}
      if a.size == 3
        h[a[1]]
      elsif a.size == 7
        h[a[3]]
      else
        Basic
      end
    end
    def self.parsed(raw)
      #raise "found other side" if raw =~ /other_side/
      cls = phrase_class(raw)
      raise "no phrase class for #{raw.inspect}" unless cls
      #raise "#{cls} #{raw}" if raw.to_s =~ /trophy/
      cls.new(:raw => raw)
    end
    
    class Base
      include FromHash
      attr_accessor :raw, :category

      fattr(:modifier) do
        a = raw.split("-")
        res = if a.size > 1
          a.first
        else
          nil
        end
        #raise 'other' if res == 'other_side'
        res
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

      def self.abilities_target(card,modifier)
        if modifier == "invokable"
          card.invokable_abilities
        elsif modifier == 'fate'
          card.fate_abilities
        else
          card.abilities
        end
      end
      def abilities_target(card)
        klass.abilities_target(card,modifier)
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

    class CompoundProc < Ability::BaseChoice
      include FromHash
      fattr(:abilities) { [] }
      def choosable_cards(*args)
        abilities.first.choosable_cards(*args)
      end
      def action_old(card,side)
        #raise 'in compound proc action method'
        abilities.first.action(card,side)
        abilities[1..-1].each { |x| x.call(side) }
      end
      def action(card,side)
        abilities.each do |a|
          if ability_needs_choice?(a)
            a.action(card,side)
          else
            a.call(side)
          end
        end
      end
      def call(*args)
        #raise 'in compound proc call method'
        abilities.each { |x| x.call(*args) }
      end

      def ability_needs_choice?(ability)
        if ability.kind_of?(Proc)
          #raise 'proc'
          false
        elsif ability.respond_to?("needs_choice?")
          ability.needs_choice?
        else
          raise 'no method'
        end
      end
      def needs_choice?
        abilities.any? { |a| ability_needs_choice?(a) }
      end


    end

    class Compound < Base
      fattr(:two_raw_phrases) do
        raise "bad" unless raw =~ /\((.+?)\) (and|or) \((.+?)\)/
        [$1,$3]
      end

      fattr(:before_phrase) do
        Phrase.parsed(two_raw_phrases[0]).tap { |x| x.category = category }
      end

      fattr(:after_phrase) do
        Phrase.parsed(two_raw_phrases[1]).tap { |x| x.category = category }
      end

      fattr(:phrases) { [before_phrase,after_phrase] }
    end

    class And < Compound
      fattr(:abilityx) do
        lambda do |side|
          phrases.each do |p|
            p.ability.call(side)
          end
        end
      end
      fattr(:ability) do
        res = CompoundProc.new
        res.abilities = phrases.map { |x| x.ability }
        res
      end
    end

    class Or < Compound
      fattr(:ability) do
        Ability::ChooseAbility.new(:optional => optional, :ability_choices => phrases.map { |x| x.ability })
      end
    end
    
    class Basic < Base
      class << self
        def basic_mod_card_proc
          lambda do |card,phrase|
            if phrase.category == :runes
              card.runes += phrase.before_clause.to_i if phrase.before_clause.to_i > 0
            elsif phrase.category == :power || phrase.category == :add_power
              card.power += phrase.before_clause.to_i
            elsif phrase.category == :add_honor
              #raise "in honor part"
              card.honor_earned = phrase.before_clause.to_i
            elsif phrase.category == :draw_cards
              phrase.abilities_target(card) << lambda do |side|
                if phrase.modifier == 'other_side'
                  phrase.draw_cards(side.other_side)
                else
                  phrase.draw_cards(side)
                end
              end
            elsif phrase.category.kind_of?(Class)
              phrase.abilities_target(card) << phrase.category.new(:optional => phrase.optional, :parent_card => card)
            else
              raise "unknown category #{phrase.category}"
            end
          end
        end
      end
      def mod_card(card)
        if modifier == 'trophy'
          trophy_card = ::Card::Hero.new
          card.trophy = trophy_card
          self.class.basic_mod_card_proc[trophy_card,self]
        else
          self.class.basic_mod_card_proc[card,self]
        end
      end
      def modifier
        super
      end
    end


    class OnceProc
      include FromHash
      attr_accessor :cond, :body, :unite
      fattr(:body_count) { 0 }
      def call(*args)
        return if body_count > 0
        if cond[*args]
          self.body_count += 1
          body[*args]
        end
      end
      def [](*args)
        call(*args)
      end

      def clone
        self.class.new(:cond => cond, :body => body, :unite => unite)
      end
      def reset!
        self.body_count = 0
      end
    end

    class On < Base
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

    class Of < Base
      fattr(:ability) do
        if %w(runes power).include?(after_word.raw)
          lambda do |side|
            #val = side.played.pool.send(after_word.raw)
            #side.played.pool.send("#{after_word.raw}=",val+before_clause.to_i)
            side.played.pool.add before_clause.to_i,after_word.raw
          end
        elsif after_word.raw == "draw"
          lambda do |side|
            before_clause.to_i.times { side.draw_one! }
          end
        elsif after_word.raw == 'this'
          #raise "this is #{category}"
          category.new(:optional => optional)
        else
          after_word.word_blk
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
      raw_cell.split(/[,;]/).each do |raw_cell_part|
        p = make_parsed_phrase_obj(raw_cell_part,method_name_or_ability_class)
        p.mod_card(card_to_setup) if p
      end
    end
    fattr(:card) do
      res = card_class.new(:name => name, :realm => realm, :honor => honor.to_i)

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
        #res.abilities << word.word_blk
        word.add_ability(res)
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
      f = File.expand_path(File.dirname(__FILE__)) + "/input/cards_spaced.csv"
      CSV.foreach(f,:headers => true, :row_sep => "\n", :quote_char => '"') do |row|
        h = {}
        row.each do |k,v|
          #puts [k,v].inspect
          if k.present?
            k = k.downcase.strip.gsub(' ','_')
            v = v.strip if v
            v = nil if v.blank?
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

Parse.reg_ability :discard_construct, Ability::DiscardConstruct.new
Parse.reg_ability :discard_all_but_one_construct, Ability::KeepOneConstruct.new

Parse.reg_ability :copy_hero, Ability::CopyHero.new

Parse.reg_ability :acquire_center, Ability::AcquireCenter.new

Parse.reg_ability :take_opponents_card, Ability::TakeOpponentsCard.new

Parse.reg_ability :acquire_construct, Ability::AcquireConstruct.new

Parse.reg_ability :return_mechana_construct_to_hand, Ability::ReturnMechanaConstructToHand.new

Parse.reg_ability :guess_top_card_for_3, Ability::GuessTopCardFor3.new

%w(power_or_rune_1 take_opponents_casrd acquire_centerx).each do |f|
  Parse.reg_ability f do |*args|
  end
end



