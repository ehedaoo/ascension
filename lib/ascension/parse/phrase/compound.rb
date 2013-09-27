module Parse
  module Phrase
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
  end
end