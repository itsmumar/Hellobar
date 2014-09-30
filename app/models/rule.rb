class Rule < ActiveRecord::Base
  MATCH_ON = {
    all: 'all',
    any: 'any'
  }

  belongs_to :site

  has_many :site_elements, dependent: :destroy
  has_many :conditions, dependent: :destroy, inverse_of: :rule

  accepts_nested_attributes_for :conditions, allow_destroy: true

  validates :name, presence: true
  validates :site, association_exists: true
  validates :priority, numericality: {
                         only_integer: true,
                         greater_than_or_equal_to: 1,
                         less_than_or_equal_to: 100
                       },
                       if: "priority.present?"

  def to_sentence
    conditions.empty? ? "Show this to everyone" : "Show this when #{conditions.map(&:to_sentence).to_sentence}"
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
end
