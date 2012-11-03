module Okubo
  class Deck < ActiveRecord::Base
    include Enumerable
    self.table_name = "okubo_decks"
    belongs_to :user, :polymorphic => true
    has_many :items, :class_name => "Okubo::Item", :dependent => :destroy

    def each &block
      _items.each do |item|
        if block_given?
          block.call item
        else
          yield item
        end
      end
    end

    def self.add_deck(user)
      create!(user)
    end

    def ==(other)
      if other.respond_to?(:items)
        source_class.find(self.items.pluck(:source_id)) == other.items
      else
        source_class.find(self.items.pluck(:source_id)) == other
      end
    end

    def _items
      source_class.find(self.items.pluck(:source_id))
    end

    def <<(source)
      raise ArgumentError.new("Word already in the stack") if include?(source)
      self.items << Okubo::Item.new(:deck => self, :source_id => source.id, :source_type => source.class.name)
    end

    def count
      self.items.count
    end

    def delete(source)
      item = Okubo::Item.new(:deck => self, :source_id => source.id, :source_type => source.class.name)
      item.destroy
    end

    def include?(source)
      Okubo::Item.exists?(:deck_id => self.id, :source_id => source.id, :source_type => source.class.name)
    end

    def untested
      source_class.find(self.items.untested.pluck(:source_id))
    end

    def failed
      source_class.find(self.items.failed.pluck(:source_id))
    end

    def known
      source_class.find(self.items.known.pluck(:source_id))
    end

    def expired
      source_class.find(self.items.expired.pluck(:source_id))
    end

    def box(number)
      source_class.find(self.items.where(:box =>  number).pluck(:source_id))
    end

    def source_class
      user.deck_name.to_s.singularize.titleize.constantize
    end
  end
end