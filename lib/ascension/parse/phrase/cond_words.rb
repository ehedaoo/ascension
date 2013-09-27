module Parse
  module Phrase
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
end