require "mongoid-sequence/version"
require "active_support/concern"

module Mongoid
  module Sequence
    extend ActiveSupport::Concern

    included do
      set_callback :validate, :before, :set_sequence, :unless => :persisted?
    end

    module ClassMethods
      attr_accessor :sequence_fields

      def sequence(field)
        self.sequence_fields ||= []
        self.sequence_fields << field
      end
    end

    def set_sequence
      sequences = self.mongo_session["__sequences"]
      self.class.sequence_fields.each do |field|
        next_sequence = sequences.find(:_id => "#{self.class.name.underscore}_#{field}").modify(
          { "$inc" => {:seq => 1} }, :upsert => true
        )
        sequence    = next_sequence['seq']
        self[field] = sequence.present? ? sequence + 1 : 1
      end if self.class.sequence_fields
    end
  end
end
