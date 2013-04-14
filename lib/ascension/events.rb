events = <<EOF
hero played
construct played
monster defeated
EOF

module Event
  class Events
    include FromHash
    attr_accessor :side
    fattr(:events) { [] }
    include Enumerable
    def each(&b)
      events.each(&b)
    end
    def <<(event)
      event.events = self
      #event.first = true if first?(event)
      self.events << event
      propagate(event)
    end
    def propagate(event)
      if side
        side.constructs.each { |c| c.handle_event(event,side) } 
        #side.played.each { |c|}
        side.played.each { |c| c.handle_event(event,side) }
      end
    end
    def first?(event)
      match = events.select { |x| x.key == event.key && x.class == event.class }#.size == 1#.tap { |x| puts "first? #{x}" }
      raise "Bad something" if match.empty?
      match.first == event
    end
    def [](i)
      events[i]
    end
    def cond?(&b)
      events.any?(&b)
    end
  end
  
  class Base
    include FromHash
    #fattr(:first) { false }
    attr_accessor :events

    fattr(:first) do
      events.first?(self)
    end
  end
  
  class CardPlayed < Base
    attr_accessor :card
    def realm
      card.realm
    end
    def card_type
      card.class
    end
    def key
      [realm,card_type]
    end
  end
  
  class MonsterKilled < Base
    attr_accessor :card
    fattr(:center) { false }
    def key
      [center]
    end
  end
  
  class CardPurchased < Base
    attr_accessor :card
    def realm
      card.realm
    end
    def card_type
      card.class
    end
    def key
      [realm,card_type]
    end
  end

  class EndTurn < Base
    def key
      [:end_turn]
    end
  end
end

class Trigger
  
end
