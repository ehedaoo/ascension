module Parse
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
  end
end

%w(basic compound cond_words).each do |f|
  load File.dirname(__FILE__) + "/phrase/#{f}.rb"
end