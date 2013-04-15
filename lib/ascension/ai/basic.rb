module AI
  class Basic
    include FromHash
    setup_mongo_persist :ai_id
    fattr(:ai_id) { rand(1000000000000000) }
    attr_accessor :side
    def game; side.game; end

    def engageable_cards
      game.center_wc.engageable_cards(side).sort_by { |x| x.engage_cost }.reverse
    end

    def play_hand!
      while side.hand.size > 0
        side.play side.hand.first
        game.handle_choices!
      end
    end

    def play_turn!
      play_hand!
      side.print_status!

      while engageable_cards.size > 0
        side.engage(engageable_cards.first.tap { |x| puts "engaging #{x.name}" })
        return unless game.handle_choices!
      end
      puts "Ending Turn"
      game.turn_manager.advance_simple!
    end

    def choice_type(choice)
      return :bad if [/Discard/,/Banish/].any? { |r| choice.class.to_s =~ r }
      :good
    end

    def handle_choice(choice)
      type = choice_type(choice)
      cards = choice.choosable_cards.sort_by { |x| x.respond_to?(:engage_cost) ? x.engage_cost||0 : -1 }
      card = (type == :bad) ? cards.first : cards.last
      choice.execute! card
    end
  end
end