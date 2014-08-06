class SiteElement < ActiveRecord::Base
  BAR_TYPES = %w{
    traffic
    email
    social/tweet_on_twitter
    social/follow_on_twitter
    social/like_on_facebook
    social/share_on_linkedin
    social/plus_one_on_google_plus
    social/pin_on_pinterest
    social/follow_on_pinterest
    social/share_on_buffer
  }

  belongs_to :rule
  belongs_to :contact_list

  validates :element_subtype, presence: true, inclusion: { in: BAR_TYPES }
  validates :rule, association_exists: true

  scope :paused, -> { where(paused: true) }
  scope :active, -> { where(paused: false) }

  delegate :site, to: :rule, allow_nil: true

  serialize :settings, Hash

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
