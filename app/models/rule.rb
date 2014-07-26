class Rule < ActiveRecord::Base
  MATCH_ON = {
    all: 'all',
    any: 'any'
  }

  belongs_to :site

  has_many :site_elements
  has_many :conditions

  accepts_nested_attributes_for :conditions, allow_destroy: true

  validates :site, association_exists: true

  def name
    read_attribute(:name) || "rule ##{id}"
  end

  def to_sentence
    conditions.empty? ? "everyone" : conditions.map(&:to_sentence).to_sentence
  end
end
