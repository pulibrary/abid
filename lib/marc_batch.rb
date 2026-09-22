# frozen_string_literal: true
require "csv"
require "application_record"
require "absolute_identifier"

# MarcBatch powers the MARC Batch form input. It's different from batches in
# that users have all the barcodes already in Alma and ready to scan, unlike the
# normal Batch where barcodes need to be generated based on a reel of barcodes
# existing.
# == Schema Information
#
# Table name: marc_batches
#
#  id                     :integer          not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :integer          not null
#  ignore_size_validation :boolean          default(FALSE)
#
# Indexes
#
#  index_marc_batches_on_user_id  (user_id)
#

class MarcBatch < ApplicationRecord
  # Stands in for the ActiveRecord::Associations::CollectionProxy this model's
  # `absolute_identifiers` used to return. Nested attributes build children that
  # are not in the database yet but must still be seen by the validations and
  # by the form, so the collection has to mix unsaved records in with the
  # persisted ones - something ApplicationRecord::Query, which only ever sees
  # the database, can't do.
  class AbsoluteIdentifierCollection
    include Enumerable

    def initialize(owner)
      @owner = owner
    end

    def build(attributes = {})
      record = AbsoluteIdentifier.new(attributes)
      # `has_many ..., as: :batch` has an automatic inverse_of in Rails (the
      # inverse name is taken from `:as`), so a child built through the
      # association already knows its parent before either is saved.
      # AbsoluteIdentifier's validations depend on that: they all begin
      # `return unless batch.is_a?(MarcBatch)`.
      record.batch = @owner
      records << record
      record
    end

    # The has_many writer Rails generated: assigning records adopts them,
    # exactly as `MarcBatch.new(absolute_identifiers: [abid])` did.
    def replace(new_records)
      new_records.each { |record| record.batch = @owner }
      @records = new_records.to_a
    end

    def each(&block) = records.each(&block)
    def size = records.size
    def length = records.length
    def first = records.first
    def empty? = records.empty?
    def blank? = records.empty?
    def present? = !records.empty?
    def to_a = records.dup
    def synchronized = records.select { |record| record.sync_status == "synchronized" }

    private

    # A new record has no children in the database, and querying for them would
    # match every AbID with a NULL batch_id.
    def records
      @records ||= @owner.new_record? ? [] : @owner.send(:association_query, :absolute_identifiers).to_a
    end
  end

  has_many :absolute_identifiers, dependent: :destroy, as: :batch
  belongs_to :user
  # Replaces `accepts_nested_attributes_for :absolute_identifiers, reject_if:
  # proc { |attributes| attributes["barcode"].blank? }`. The writer is
  # `#absolute_identifiers_attributes=` below; these two declarations are the
  # autosave callbacks Rails installed alongside it, in the position Rails
  # installed them (before the validations declared below, so that the child
  # errors `abids_unique_holding_ids` adds are not cleared by revalidation).
  validate :validate_absolute_identifiers
  after_save :save_absolute_identifiers
  validate :abids_unique_holding_ids
  # Written as `presence: {if: ...}` rather than `presence: true, if: ...`
  # because ApplicationRecord#validates turns each key into its own validation
  # and would drop a top-level `if:`. Rails treats the two spellings
  # identically.
  validates :prefix, presence: { if: :new_record? }
  attr_accessor :prefix
  before_validation :populate_abid_prefixes

  def generate_abid
    true
  end

  def synchronized?
    absolute_identifiers.synchronized.size == absolute_identifiers.size
  end

  def synchronize
    absolute_identifiers.each(&:synchronize)
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << csv_attributes(absolute_identifiers.first).keys

      absolute_identifiers.each do |record|
        csv << csv_attributes(record)
      end
    end
  end

  def csv_attributes(record)
    {
      barcode: record.barcode,
      holding_id: record.holding_id,
      abid: record.full_identifier,
      previous_call_number: record.previous_call_number
    }
  end

  def absolute_identifiers
    @absolute_identifiers ||= AbsoluteIdentifierCollection.new(self)
  end

  # `has_many` generates a writer too, which the specs use as
  # `FactoryBot.create(:marc_batch, absolute_identifiers: [abid])`.
  def absolute_identifiers=(records)
    absolute_identifiers.replace(Array(records))
  end

  # The writer `accepts_nested_attributes_for` generated. Rails accepted either
  # an array of attribute hashes or the hash-of-index-hashes the form submits,
  # and normalised each one with `with_indifferent_access` before handing it to
  # `reject_if` - hence the two-key lookup for "barcode". Neither `:id` nor
  # `:_destroy` is handled: MarcBatchesController permits only :barcode,
  # :prefix and :pool_identifier, so neither can ever arrive.
  def absolute_identifiers_attributes=(attributes_collection)
    attributes_collection = attributes_collection.values if attributes_collection.is_a?(Hash)
    attributes_collection.each do |attributes|
      attributes = attributes.to_h
      next if reject_absolute_identifier?(attributes)
      absolute_identifiers.build(attributes)
    end
  end

  private

  def populate_abid_prefixes
    return unless new_record? && !value_blank?(prefix)
    absolute_identifiers.each do |abid|
      abid.prefix ||= prefix
    end
  end

  def abids_unique_holding_ids
    absolute_identifiers.each(&:cache_holding_id)
    absolute_identifiers.group_by(&:holding_id).each do |_holding_id, group|
      next unless group.map(&:prefix).uniq.length != 1
      barcodes = group.map(&:barcode)
      group.each do |absolute_identifier|
        absolute_identifier.errors.add(:barcode, "has the same holding ID but different prefix as #{to_sentence(barcodes - [absolute_identifier.barcode])}.")
      end
      errors.add(:base, "Issue with barcodes #{to_sentence(barcodes)}")
    end
  end

  # `reject_if: proc { |attributes| attributes["barcode"].blank? }`.
  def reject_absolute_identifier?(attributes)
    value_blank?(attributes.key?("barcode") ? attributes["barcode"] : attributes[:barcode])
  end

  # The validation half of Rails' autosave association: validate the children
  # that are about to be written and copy their errors onto the parent.
  # Unchanged, already-persisted children are left alone, as Rails left them.
  # The error key is Rails' "absolute_identifiers.barcode" with the dot written
  # as an underscore, because ApplicationRecord::Errors.humanize does not
  # replace dots the way ActiveModel's human_attribute_name does; this spelling
  # produces the same full message, "Absolute identifiers barcode ...".
  def validate_absolute_identifiers
    absolute_identifiers_to_autosave.each do |record|
      next if record.valid?
      record.errors.to_hash.each do |attribute, messages|
        messages.each do |message|
          errors.add(:"absolute_identifiers_#{attribute}", message)
        end
      end
    end
  end

  # The save half of Rails' autosave association. It runs inside the
  # transaction ApplicationRecord#save opens, so a child that cannot be written
  # takes the whole batch down with it, as `raise ActiveRecord::Rollback` did.
  # The batch only has an id once it has been inserted, so the parent is
  # re-assigned here to fill in batch_id.
  def save_absolute_identifiers
    absolute_identifiers_to_autosave.each do |record|
      record.batch = self
      raise ApplicationRecord::RecordInvalid, record unless record.save
    end
  end

  def absolute_identifiers_to_autosave
    absolute_identifiers.select(&:new_record?)
  end

  # ActiveSupport's Array#to_sentence with the default locale: "a", "a and b",
  # "a, b, and c". Its output is embedded in the errors above.
  def to_sentence(array)
    array = array.map(&:to_s)
    case array.length
    when 0 then ""
    when 1 then array[0]
    when 2 then "#{array[0]} and #{array[1]}"
    else "#{array[0...-1].join(', ')}, and #{array[-1]}"
    end
  end

  # Both `instantiate` and `reload` come through here, and both mean the
  # collection built for the old state of the record is stale.
  def initialize_from_row(row)
    super
    @absolute_identifiers = nil
    self
  end
end
