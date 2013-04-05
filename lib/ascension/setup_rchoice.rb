RChoice::Choice.setup_mongo_persist :optional, :name, :options
RChoice::Option.setup_mongo_persist :base_obj

class Choices
  class << self
    fattr(:list) { [] }
    def setup_chooser!
      Ability::CardChoice.chooser = lambda { |choice| self.list << choice }
    end
  end
end
