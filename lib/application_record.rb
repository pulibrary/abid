# frozen_string_literal: true

require "json"
require "time"

# Minimal persistence/validation layer backing the ported domain models.
#
# The Rails app leaned on ActiveRecord for attributes, validations, callbacks,
# associations and querying. This port must not use any Rails-ecosystem
# library, so the small slice of that behaviour the application actually relies
# on is reimplemented here in plain Ruby on top of Sequel (via hanami-db's
# gateway). It is deliberately NOT a general-purpose ORM: it implements exactly
# what app/models/*.rb and the specs use, and reproduces ActiveRecord's
# observable behaviour — including error-message wording and callback ordering.
class ApplicationRecord
  class RecordNotFound < StandardError; end

  class RecordInvalid < StandardError
    attr_reader :record

    def initialize(record)
      @record = record
      super("Validation failed: #{record.errors.full_messages.join(', ')}")
    end
  end

  # Mirrors the subset of ActiveModel::Errors the app and views use. Message
  # wording matters: specs assert on "Prefix can't be blank" and
  # "Start box can't be blank", which is Rails' humanized-attribute format.
  class Errors
    def initialize = @entries = []

    def add(attribute, message) = @entries << [attribute.to_sym, message]
    def [](attribute) = @entries.select { |a, _| a == attribute.to_sym }.map(&:last)
    def clear = @entries.clear
    def empty? = @entries.empty?
    def any? = !empty?
    def key?(attribute) = @entries.any? { |a, _| a == attribute.to_sym }
    def attribute_names = @entries.map(&:first).uniq
    def to_hash = @entries.group_by(&:first).transform_values { |v| v.map(&:last) }
    def size = @entries.size
    def count = @entries.size

    # Insertion order, matching ActiveModel::Errors in Rails 6.1+.
    def full_messages = @entries.map { |attribute, message| full_message(attribute, message) }

    def full_messages_for(attribute)
      self[attribute].map { |message| full_message(attribute, message) }
    end

    # Rails renders :base errors bare, and every other attribute as
    # "Humanized attribute message".
    def full_message(attribute, message)
      return message if attribute.to_sym == :base

      "#{self.class.humanize(attribute)} #{message}"
    end

    def self.humanize(attribute)
      attribute.to_s.tr(".", "_").tr("_", " ").sub(/\A\w/, &:upcase)
    end
  end

  # Chainable query object over a Sequel dataset, materialising records lazily.
  # Supports the handful of relation methods the app uses: where, where.not,
  # order, pick, first, last, size/count, each/map/group_by, empty?/blank?.
  class Query
    include Enumerable

    # Backs `where.not(...)`: Rails' `where` with no arguments returns a chain
    # object whose #not negates the following conditions.
    class WhereChain
      def initialize(query) = @query = query
      def not(conditions) = @query.exclude(conditions)
    end

    attr_reader :model, :dataset

    def initialize(model, dataset)
      @model = model
      @dataset = dataset
    end

    def where(conditions = nil)
      return WhereChain.new(self) if conditions.nil?

      chain(dataset.where(cast_conditions(conditions)))
    end

    def exclude(conditions) = chain(dataset.exclude(cast_conditions(conditions)))
    def order(*args) = chain(dataset.order(*order_terms(args)))
    def limit(n) = chain(dataset.limit(n))

    # Rails' ActiveRecord::Relation#pick: first value of one column, or nil.
    def pick(column) = dataset.get(column)

    def each(&block) = to_a.each(&block)
    def to_a = @to_a ||= dataset.all.map { |row| model.instantiate(row) }
    def first = (row = dataset.first) && model.instantiate(row)
    def last = (row = dataset.order(Sequel.desc(:id)).first) && model.instantiate(row)
    def size = dataset.count
    def count = dataset.count
    def length = to_a.length
    def empty? = dataset.count.zero?
    def blank? = empty?
    def present? = !empty?
    def delete_all = dataset.delete

    # Rails' relation-level update: assigns and saves every matched record, so
    # callbacks still run (spec/factories/batches.rb relies on this).
    def update(attributes)
      to_a.each { |record| record.update(attributes) }
    end

    def inspect = to_a.inspect

    private

    def chain(new_dataset) = self.class.new(model, new_dataset)

    # Cast each condition value to its column's type, as ActiveRecord did.
    # Without this a Symbol value reaches Sequel as a column identifier:
    # `where(provider: :cas)` becomes `"provider" = "cas"`, which Postgres
    # rejects with `column "cas" does not exist`. The real OmniAuth CAS
    # strategy names the provider with a Symbol, so every login hit this.
    def cast_conditions(conditions)
      return conditions unless conditions.is_a?(Hash)

      conditions.to_h { |column, value| [column, cast_condition_value(column, value)] }
    end

    def cast_condition_value(column, value)
      return value unless column.respond_to?(:to_sym)
      return value unless model.column_names.include?(column.to_sym)

      case value
      when nil, Range, Sequel::SQL::Expression then value
      when Array then value.map { |element| model.cast_value(column.to_sym, element) }
      else model.cast_value(column.to_sym, value)
      end
    end

    # Accepts `order(:suffix)`, `order(suffix: :desc)` and raw Sequel terms.
    def order_terms(args)
      args.flat_map do |arg|
        case arg
        when Hash
          arg.map { |column, direction| direction.to_sym == :desc ? Sequel.desc(column) : Sequel.asc(column) }
        else
          [arg]
        end
      end
    end
  end

  # --- class-level configuration -------------------------------------------

  class << self
    def inherited(subclass)
      super
      subclass.instance_variable_set(:@attribute_defaults, attribute_defaults.dup)
      subclass.instance_variable_set(:@validations, validations.dup)
      subclass.instance_variable_set(:@callbacks, callbacks.transform_values(&:dup))
      subclass.instance_variable_set(:@associations, associations.dup)
    end

    def attribute_defaults = @attribute_defaults ||= {}
    def validations = @validations ||= []
    def associations = @associations ||= {}

    def callbacks
      @callbacks ||= { before_validation: [], before_save: [], after_save: [], before_destroy: [] }
    end

    def table_name = @table_name ||= default_table_name

    def default_table_name
      word = name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      # The app's model names pluralise regularly (batches, marc_batches,
      # users, absolute_identifiers), so a simple rule suffices.
      word.end_with?("s", "x", "ch", "sh") ? "#{word}es" : "#{word}s"
    end

    def db = Hanami.app["db.gateway"].connection
    def dataset = db[table_name.to_sym]
    def query = relation_class.new(self, dataset)

    # Column names and types are read from the live schema, so the models stay
    # in step with config/db/migrate without restating every column.
    def columns
      @columns ||= schema_info.to_h { |column, info| [column, info[:type]] }
    end

    # Database-level defaults (generate_abid = true, batch_type = 'Batch',
    # ignore_size_validation = false, provider = 'cas'). ActiveRecord applies
    # these to new records, and the app relies on it.
    def column_defaults
      @column_defaults ||= schema_info.each_with_object({}) do |(column, info), defaults|
        next if info[:ruby_default].nil?

        defaults[column] = info[:ruby_default]
      end
    end

    def schema_info = @schema_info ||= db.schema(table_name.to_sym)

    def column_names = columns.keys

    # Casting lives on the class because both attribute assignment and query
    # conditions need it. ActiveRecord cast a condition value to its column's
    # type before building SQL; Sequel does not, and crucially it treats a
    # Symbol VALUE as a column reference, so `where(provider: :cas)` compiled
    # to `"provider" = "cas"` and Postgres rejected it.
    def cast_value(column, value)
      return nil if value.nil?

      case columns[column]
      when :integer then cast_integer(value)
      when :string then value.to_s
      when :boolean then cast_boolean(value)
      when :json, :jsonb then cast_json(value)
      else value
      end
    end

    def cast_integer(value)
      return value if value.is_a?(Integer)
      return nil if value.to_s.strip.empty?

      Integer(value, exception: false)
    end

    def cast_boolean(value)
      case value
      when true, "1", "true", "t", 1 then true
      when false, "0", "false", "f", 0 then false
      end
    end

    def cast_json(value)
      case value
      when String
        begin
          JSON.parse(value)
        rescue JSON::ParserError
          value
        end
      when Hash, Array then value
      else
        # Sequel wraps jsonb columns in JSONBHash/JSONBArray delegators, which
        # are not Hash/Array subclasses, so Sequel.pg_jsonb_wrap rejects them
        # on the way back out. Unwrap to plain Ruby on read.
        return value.to_hash if value.respond_to?(:to_hash)
        return value.to_ary if value.respond_to?(:to_ary)

        value
      end
    end

    # Declares an app-level default, as Rails' `attribute :x, default: y` did.
    # Note this is NOT a database default, matching the original.
    def attribute(name, _type = nil, default: nil)
      attribute_defaults[name.to_sym] = default
    end

    # `validates :prefix, presence: true, if: :new_record?` — :if/:unless are
    # shared conditions across every rule in the call, not rules themselves.
    def validates(*attributes, **rules)
      conditions = rules.slice(:if, :unless)
      rules = rules.except(:if, :unless)

      attributes.each do |attribute|
        rules.each do |rule, options|
          options = options.is_a?(Hash) ? conditions.merge(options) : { value: options, **conditions }
          validations << [:builtin, attribute, rule, options]
        end
      end
    end

    # `scope :synchronized, -> { where(sync_status: "synchronized") }`.
    # Defined on both the model and its relation class so it chains from an
    # association, as `batch.absolute_identifiers.synchronized` does.
    def scope(name, body)
      relation_class.define_method(name) { instance_exec(&body) }
      define_singleton_method(name) { query.public_send(name) }
    end

    # Each model gets its own Query subclass so scopes do not leak between
    # models and survive chaining.
    def relation_class
      @relation_class ||= const_set(:Relation, Class.new(Query))
    end

    def validate(method_name, **options) = validations << [:method, method_name, nil, options]

    def before_validation(method_name) = callbacks[:before_validation] << method_name
    def before_save(method_name) = callbacks[:before_save] << method_name
    def after_save(method_name) = callbacks[:after_save] << method_name
    def before_destroy(method_name) = callbacks[:before_destroy] << method_name

    # --- associations ---

    # `as:` marks the polymorphic inverse: children store batch_id + batch_type.
    def has_many(name, scope = nil, dependent: nil, as: nil, class_name: nil) # rubocop:disable Naming/PredicateName
      associations[name] = { type: :has_many, scope: scope, dependent: dependent, as: as, class_name: class_name }
      define_method(name) { association_query(name) }
      before_destroy(:destroy_dependent_associations) if dependent == :destroy
    end

    # Rails 6.1 defaults (which this app loaded) make belongs_to required
    # unless `optional: true`, adding a "must exist" error.
    def belongs_to(name, polymorphic: false, class_name: nil, optional: false)
      associations[name] = { type: :belongs_to, polymorphic: polymorphic, class_name: class_name, optional: optional }
      validations << [:belongs_to, name, nil, {}] unless optional
      define_method(name) { belongs_to_target(name) }
      define_method("#{name}=") { |value| assign_belongs_to(name, value) }
    end

    # --- querying ---

    def all = query
    def where(conditions = nil) = query.where(conditions)
    def order(*args) = query.order(*args)
    def first = query.first
    def last = query.last
    def count = query.count

    def find_by(conditions) = query.where(conditions).first

    def find(id)
      find_by(id: id) || raise(RecordNotFound, "Couldn't find #{name} with 'id'=#{id}")
    end

    def create(attributes = {})
      new(attributes).tap(&:save)
    end

    def create!(attributes = {})
      record = new(attributes)
      raise RecordInvalid, record unless record.save

      record
    end

    def find_or_create_by(attributes) = find_by(attributes) || create(attributes)

    # Builds a record from an existing database row (already persisted).
    def instantiate(row)
      record = allocate
      record.send(:initialize_from_row, row)
      record
    end
  end

  # --- instance ------------------------------------------------------------

  attr_reader :errors

  def initialize(attributes = {})
    @attributes = {}
    @persisted = false
    @errors = Errors.new
    self.class.column_names.each { |column| @attributes[column] = nil }
    self.class.column_defaults.each { |column, default| @attributes[column] = default }
    self.class.attribute_defaults.each { |column, default| @attributes[column] = default }
    assign_attributes(attributes)
  end

  def assign_attributes(attributes)
    (attributes || {}).each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def attributes = @attributes.dup

  def persisted? = @persisted
  def new_record? = !@persisted
  def id = @attributes[:id]

  def ==(other)
    other.is_a?(self.class) && !id.nil? && id == other.id
  end
  alias eql? ==

  def hash = [self.class, id].hash

  def valid?
    errors.clear
    run_callbacks(:before_validation)
    self.class.validations.each { |kind, a, b, c| run_validation(kind, a, b, c) }
    errors.empty?
  end

  def invalid? = !valid?

  def save
    return false unless valid?

    self.class.db.transaction do
      save_belongs_to_associations
      run_callbacks(:before_save)
      @persisted ? update_row : insert_row
      @persisted = true
      run_callbacks(:after_save)
    end
    true
  end

  def save!
    raise RecordInvalid, self unless save

    true
  end

  def update(attributes)
    assign_attributes(attributes)
    save
  end

  def destroy
    self.class.db.transaction do
      run_callbacks(:before_destroy)
      self.class.dataset.where(id: id).delete
    end
    @persisted = false
    self
  end

  def reload
    row = self.class.dataset.where(id: id).first
    raise RecordNotFound, "Couldn't find #{self.class.name} with 'id'=#{id}" unless row

    initialize_from_row(row)
    self
  end

  private

  def initialize_from_row(row)
    @attributes = {}
    @persisted = true
    @errors = Errors.new
    @association_cache = {}
    row.each { |column, value| @attributes[column] = cast(column, value) }
    self
  end

  def cast(column, value) = self.class.cast_value(column, value)

  def insert_row
    now = Time.now.utc
    @attributes[:created_at] ||= now
    @attributes[:updated_at] = now
    @attributes[:id] = self.class.dataset.insert(persistable_attributes.reject { |k, _| k == :id })
  end

  def update_row
    @attributes[:updated_at] = Time.now.utc
    self.class.dataset.where(id: id).update(persistable_attributes.reject { |k, _| k == :id })
  end

  def persistable_attributes
    @attributes.select { |column, _| self.class.column_names.include?(column) }
               .to_h { |column, value| [column, serialize(column, value)] }
  end

  def serialize(column, value)
    case self.class.columns[column]
    when :json, :jsonb then value.nil? ? nil : Sequel.pg_jsonb_wrap(value)
    else value
    end
  end

  # Rails' belongs_to autosave: a new associated record is saved before the
  # owner, so the foreign key can be set. FactoryBot relies on this —
  # `build(:marc_batch)` builds an unsaved User and `save!` must persist it.
  def save_belongs_to_associations
    self.class.associations.each do |name, definition|
      next unless definition[:type] == :belongs_to

      target = association_cache[name]
      next if target.nil? || target.persisted?

      target.save
      @attributes[:"#{name}_id"] = target.id
      @attributes[:"#{name}_type"] = target.class.name if definition[:polymorphic]
    end
  end

  def run_callbacks(kind)
    self.class.callbacks[kind].each { |method_name| send(method_name) }
  end

  def run_validation(kind, first, rule, options)
    case kind
    when :method then send(first)
    when :builtin then run_builtin_validation(first, rule, options)
    when :belongs_to then validate_belongs_to(first)
    end
  end

  def run_builtin_validation(attribute, rule, options)
    return unless conditions_met?(options)

    case rule
    when :presence then validate_presence(attribute)
    when :numericality then validate_numericality(attribute, options)
    end
  end

  # Honours the :if / :unless shared across a `validates` call.
  def conditions_met?(options)
    return true unless options.is_a?(Hash)
    return false if options[:if] && !send(options[:if])
    return false if options[:unless] && send(options[:unless])

    true
  end

  def validate_presence(attribute)
    errors.add(attribute, "can't be blank") if value_blank?(public_send(attribute))
  end

  # Rails 6.1 defaults add this to every non-optional belongs_to. The message
  # is "must exist", not "can't be blank".
  def validate_belongs_to(name)
    errors.add(name, "must exist") if public_send(name).nil?
  end

  def validate_numericality(attribute, options)
    value = public_send(attribute)
    return if options[:allow_nil] && value.nil?

    if value.nil? || !value.is_a?(Numeric)
      errors.add(attribute, "is not a number")
      return
    end

    minimum = options[:greater_than_or_equal_to]
    return if minimum.nil?

    minimum = minimum.respond_to?(:call) ? minimum.call(self) : minimum
    errors.add(attribute, "must be greater than or equal to #{minimum}") if value < minimum
  end

  # Matches ActiveSupport's Object#blank? for the types the app validates:
  # nil, whitespace-only strings, and empty collections.
  def value_blank?(value)
    case value
    when nil, false then true
    when String then value.strip.empty?
    when Array, Hash then value.empty?
    else value.respond_to?(:empty?) ? value.empty? : false
    end
  end

  # --- associations ---

  # ROM/Sequel do not cascade, and absolute_identifiers.batch_id has no foreign
  # key, so `dependent: :destroy` is honoured here instead.
  def destroy_dependent_associations
    self.class.associations.each do |name, definition|
      next unless definition[:type] == :has_many && definition[:dependent] == :destroy

      # Deliberately uses the raw association query rather than the public
      # reader: MarcBatch overrides and memoises its reader with a collection
      # proxy that can hold a stale (empty) backing array.
      association_query(name).each(&:destroy)
    end
  end

  def association_cache = @association_cache ||= {}

  def association_query(name)
    definition = self.class.associations.fetch(name)
    target = association_class(name, definition)
    foreign_key = definition[:as] ? :"#{definition[:as]}_id" : :"#{association_foreign_key}"
    conditions = { foreign_key => id }
    conditions[:"#{definition[:as]}_type"] = self.class.name if definition[:as]
    scope = target.where(conditions)
    definition[:scope] ? definition[:scope].call(scope) : scope
  end

  def association_foreign_key = "#{self.class.name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase}_id"

  def association_class(name, definition)
    Object.const_get(definition[:class_name] || singularize_constant(name))
  end

  def singularize_constant(name)
    word = name.to_s
    singular =
      if word.end_with?("ches", "shes", "xes", "sses")
        word.sub(/es\z/, "")
      else
        word.sub(/s\z/, "")
      end
    singular.split("_").map { |part| part.sub(/\A\w/, &:upcase) }.join
  end

  def belongs_to_target(name)
    definition = self.class.associations.fetch(name)
    return association_cache[name] if association_cache.key?(name)

    association_cache[name] =
      if definition[:polymorphic]
        type = @attributes[:"#{name}_type"]
        foreign_id = @attributes[:"#{name}_id"]
        type && foreign_id ? Object.const_get(type).find_by(id: foreign_id) : nil
      else
        foreign_id = @attributes[:"#{name}_id"]
        foreign_id ? association_class(name, definition).find_by(id: foreign_id) : nil
      end
  end

  def assign_belongs_to(name, value)
    definition = self.class.associations.fetch(name)
    association_cache[name] = value
    @attributes[:"#{name}_id"] = value&.id
    @attributes[:"#{name}_type"] = value&.class&.name if definition[:polymorphic]
    value
  end

  # Attribute readers/writers are defined on demand from the live schema.
  def method_missing(name, *args)
    attribute = name.to_s.delete_suffix("=").to_sym
    return super unless self.class.column_names.include?(attribute)

    if name.to_s.end_with?("=")
      @attributes[attribute] = cast(attribute, args.first)
    else
      @attributes[attribute]
    end
  end

  def respond_to_missing?(name, include_private = false)
    attribute = name.to_s.delete_suffix("=").to_sym
    self.class.column_names.include?(attribute) || super
  end
end
