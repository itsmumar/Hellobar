class Rule < ActiveRecord::Base
  MATCH_ON = {
    all: 'all',
    any: 'any'
  }.freeze

  acts_as_paranoid

  belongs_to :site, touch: true, inverse_of: :rules
  has_many :site_elements, dependent: :destroy
  has_many :active_site_elements, -> { merge(SiteElement.active) }, class_name: 'SiteElement', inverse_of: :rule
  has_many :conditions, dependent: :destroy, inverse_of: :rule

  accepts_nested_attributes_for :conditions, allow_destroy: true

  scope :editable, -> { where(editable: true) }

  validates_associated :conditions
  validates :name, presence: true
  validates :site, association_exists: true

  def self.defaults
    everyone = Rule.new(name: 'Everyone',          match: MATCH_ON[:all], editable: false)
    mobile =   Rule.new(name: 'Mobile Visitors',   match: MATCH_ON[:all], editable: false)
    homepage = Rule.new(name: 'Homepage Visitors', match: MATCH_ON[:all], editable: false)

    mobile.conditions.build segment: 'DeviceCondition', operand: :is, value: 'mobile'
    homepage.conditions.build segment: 'UrlPathCondition', operand: :is, value: ['/']

    [everyone, mobile, homepage]
  end

  def to_sentence
    if conditions.empty?
      'Show this to everyone'
    elsif conditions.size == 1
      conditions.first.to_sentence
    elsif conditions.size == 2
      "#{ conditions.first.to_sentence } and 1 other condition"
    else
      "#{ conditions.first.to_sentence } and #{ conditions.size - 1 } other conditions"
    end
  end

  # does this rule match the same conditions as some other rule?
  def same_as?(other_rule)
    if conditions.count == 0 && other_rule.conditions.count == 0
      true
    elsif conditions.count != other_rule.conditions.count
      false
    elsif conditions.count > 1 && match != other_rule.match
      false
    else
      # does each condition match some condition in other_rule?
      conditions.all? do |condition|
        other_rule.conditions.any? do |other_condition|
          condition.segment == other_condition.segment &&
            condition.operand == other_condition.operand &&
            condition.value == other_condition.value
        end
      end
    end
  end

  def update_conditions(conditions_attributes)
    transaction do
      conditions_attributes.each_value do |attributes|
        if attributes['id']
          c = conditions.detect { |x| x.id == attributes['id'].to_i }
          if attributes['_destroy'] == 'true'
            c.destroy
          else
            attributes.delete('_destroy')
            c.assign_attributes(attributes)
            c = c.becomes(c.segment.constantize)
            c.save!
          end
        else
          conditions.create!(attributes)
        end
      end
    end
    true
  rescue StandardError
    false
  end

  def nested_error_messages
    error_messages = conditions.each.with_object([]) do |condition, memo|
      condition.errors.full_messages.each do |message|
        memo << message.downcase
      end
    end

    errors.full_messages.each do |message|
      error_messages << message.downcase unless message == 'Conditions is invalid'
    end

    error_messages
  end
end
