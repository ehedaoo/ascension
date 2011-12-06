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
    def <<(event)
      event.first = true if first?(event)
      self.events << event
      propagate(event)
    end
    def propagate(event)
      side.constructs.each { |c| c.apply_triggers(event,side) } if side
    end
    def first?(event)
      events.select { |x| x.key == event.key && x.class == event.class }.empty?#.tap { |x| puts "first? #{x}" }
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
    fattr(:first) { false }
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
end

class Trigger
  
end
