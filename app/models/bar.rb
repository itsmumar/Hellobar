class Bar < ActiveRecord::Base
  belongs_to :rule_set

  validates :goal, presence: true

  scope :paused, -> { where(paused: true) }
  scope :active, -> { where(paused: false) }

  delegate :site, to: :rule_set, allow_nil: true

  GOAL_TYPES = %w{ DirectTraffic CollectEmail }

  def total_views
    return 0 unless site

    this_data = site.get_all_time_data.detect{|b| b.bar_id.to_i == self.id.to_i}
    this_data.try(:views) || 0
  end

  def total_conversions
    return 0 unless site

    this_data = site.get_all_time_data.detect{|b| b.bar_id.to_i == self.id.to_i}
    this_data.try(:conversions) || 0
  end
end
