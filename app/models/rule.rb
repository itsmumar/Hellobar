class Rule < ActiveRecord::Base
  MATCH_ON = {
    all: 'all',
    any: 'any'
  }

  belongs_to :site

  has_many :site_elements
  has_many :conditions, inverse_of: :rule

  accepts_nested_attributes_for :conditions, allow_destroy: true

  validates :site, association_exists: true
  validates :priority, numericality: {
                         only_integer: true,
                         greater_than_or_equal_to: 1,
                         less_than_or_equal_to: 100
                       },
                       if: "priority.present?"

  def name
    read_attribute(:name) || "rule ##{id}"
  end

  def to_sentence
    conditions.empty? ? "everyone" : conditions.map(&:to_sentence).to_sentence
  end
end
