class SiteElement < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions

  SYSTEM_FONTS = %w[Arial Georgia Impact Tahoma Times\ New\ Roman Verdana].freeze
  DEFAULT_EMAIL_THANK_YOU = 'Thank you for signing up!'.freeze
  DEFAULT_FREE_EMAIL_THANK_YOU = "#{ DEFAULT_EMAIL_THANK_YOU } If you would like this sort of bar on your site...".freeze
  AFTER_EMAIL_ACTION_MAP = {
    0 => :show_default_message,
    1 => :custom_thank_you_text,
    2 => :redirect
  }.freeze

  WHITELISTED_TAGS = %w[p strong em u a s sub sup img span ul ol li br hr table tbody tr th td blockquote].freeze
  WHITELISTED_ATTRS = %w[style class href target alt src data-hb-geolocation].freeze

  # valid bar types and their conversion units
  BAR_TYPES = {
    # themes type `generic`
    'call'                            => 'Calls',
    'traffic'                         => 'Clicks',
    'email'                           => 'Emails',
    'announcement'                    => 'Conversions',
    'social/tweet_on_twitter'         => 'Tweets',
    'social/follow_on_twitter'        => 'Follows',
    'social/like_on_facebook'         => 'Likes',
    'social/plus_one_on_google_plus'  => "+1's",
    'social/pin_on_pinterest'         => 'Pins',
    'social/follow_on_pinterest'      => 'Follows',
    'social/share_on_buffer'          => 'Shares',
    'social/share_on_linkedin'        => 'Shares',
    'question'                        => 'Question',

    # themes type `template`
    'traffic_growth'                  => 'Emails'
  }.freeze

  TEMPLATE_NAMES = %w[traffic_growth].freeze
  SHORT_SUBTYPES = %w[traffic email call social announcement].freeze

  belongs_to :rule, touch: true
  belongs_to :contact_list
  belongs_to :active_image, class_name: 'ImageUpload', dependent: :destroy
  belongs_to :theme
  belongs_to :font

  acts_as_paranoid

  validates :element_subtype, presence: true, inclusion: { in: BAR_TYPES.keys }
  validates :rule, association_exists: true
  validates :background_color, :border_color, :button_color, :link_color, :text_color, hex_color: true
  validates :contact_list, association_exists: true, if: :email?
  validate :site_is_capable_of_creating_element, unless: :persisted?
  validate :redirect_has_url, if: :email?
  validate :validate_thank_you_text, if: :email?
  validate :subscription_for_custom_targeting

  scope :paused, -> { where("paused = true and type != 'ContentUpgrade'") }
  scope :active, -> { where("paused = false and type != 'ContentUpgrade'") }
  scope :paused_content_upgrades, -> { where("paused = true and type = 'ContentUpgrade'") }
  scope :active_content_upgrades, -> { where("paused = false and type = 'ContentUpgrade'") }
  scope :has_performance, -> { where('element_subtype != ?', 'announcement') }
  scope :bars, -> { where(type: 'Bar') }
  scope :sliders, -> { where(type: 'Slider') }
  scope :modals_and_takeovers, -> { where(type: ['Modal', 'Takeover']) }
  scope :email_subtype, -> { where(element_subtype: 'email') }
  scope :social_subtype, -> { where("element_subtype LIKE '%social%'") }
  scope :traffic_subtype, -> { where(element_subtype: 'traffic') }
  scope :call_subtype, -> { where(element_subtype: 'call') }
  scope :announcement_subtype, -> { where(element_subtype: 'announcement') }
  scope :recent, ->(limit) { where('site_elements.created_at > ?', 2.weeks.ago).order('created_at DESC').limit(limit).select { |se| se.announcement? || se.converted? } }
  scope :matching_content, ->(*query) { matching(:content, *query) }
  scope :wordpress_bars, -> { where.not(wordpress_bar_id: nil) }

  delegate :site, :site_id, to: :rule, allow_nil: true
  delegate :image_uploads, to: :site
  delegate :url, :large_url, :modal_url, to: :active_image, allow_nil: true, prefix: :image
  delegate :image_file_name, to: :active_image, allow_nil: true
  delegate :conversion_rate, to: :statistics

  store :settings, coder: Hash
  serialize :blocks, Array

  after_create :track_creation

  NOT_CLONEABLE_ATTRIBUTES = %i[
    element_subtype
    id
    created_at
    updated_at
    deleted_at
    paused
  ].freeze

  QUESTION_DEFAULTS = {
    question: 'First time here?',
    answer1: 'Yes',
    answer2: 'No',
    answer1response: 'Welcome! Let’s get started...',
    answer2response: 'Welcome back! Check out our new sale.',
    answer1link_text: 'Take the tour',
    answer2link_text: 'Shop now'
  }.freeze

  QUESTION_DEFAULTS.keys.each do |attr_name|
    define_method attr_name do
      self[attr_name].presence || QUESTION_DEFAULTS[attr_name] if use_question?
    end
  end

  def self.types
    [Bar, Modal, Slider, Takeover, ContentUpgrade, Alert].map(&:name)
  end

  def caption=(c_value)
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    c_value = white_list_sanitizer.sanitize(c_value, tags: WHITELISTED_TAGS, attributes: WHITELISTED_ATTRS)
    self[:caption] = c_value
  end

  def headline=(h_value)
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    h_value = white_list_sanitizer.sanitize(h_value, tags: WHITELISTED_TAGS, attributes: WHITELISTED_ATTRS)
    h_value = 'Hello. Add your message here.' if h_value.blank?
    self[:headline] = h_value
  end

  def link_text=(lt_value)
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    lt_value = white_list_sanitizer.sanitize(lt_value, tags: WHITELISTED_TAGS, attributes: WHITELISTED_ATTRS)
    self[:link_text] = lt_value
  end

  def fonts
    (headline.to_s + caption.to_s + link_text.to_s).scan(/font-family: "?(.*?)"?,/).flatten.uniq - SYSTEM_FONTS
  end

  def related_site_elements
    site.site_elements.where.not(id: id).where(SiteElement.arel_table[:element_subtype].matches("%#{ short_subtype }%"))
  end

  def activity_message?
    converted? || announcement?
  end

  def cloneable_attributes
    attributes.reject { |k, _| NOT_CLONEABLE_ATTRIBUTES.include?(k.to_sym) }
  end

  def total_views
    statistics.views
  end

  def total_conversions
    statistics.conversions
  end

  def conversion_percentage
    statistics.conversion_rate
  end

  def converted?
    total_conversions > 0
  end

  def toggle_paused!
    update paused: !paused?
  end

  def short_subtype
    element_subtype[/(\w+)/]
  end

  def track_creation
    analytics_track_site_element_creation!
    onboarding_track_site_element_creation!
  end

  def analytics_track_site_element_creation!
    Analytics.track(
      :site, site_id, 'Created Site Element',
      site_element_id: id,
      type: element_subtype,
      style: type.to_s.downcase
    )
  end

  def onboarding_track_site_element_creation!
    site.owners.each do |user|
      user.onboarding_status_setter.created_element!
    end
  end

  def self.all_templates
    [].tap do |templates|
      types.each do |type|
        BAR_TYPES.keys.each do |subtype|
          if TEMPLATE_NAMES.include?(subtype)
            types = Theme.find_by(id: subtype.tr('_', '-')).element_types
            if types.include?(type)
              templates << "#{ type.downcase }_#{ subtype }"
            end
          else
            templates << "#{ type.downcase }_#{ subtype }"
          end
        end
      end
    end
  end

  def primary_color
    background_color
  end

  def secondary_color
    button_color
  end

  def display_thank_you_text
    if show_default_email_message?
      default_email_thank_you_text
    else
      self[:thank_you_text].presence || default_email_thank_you_text
    end
  end

  def default_email_thank_you_text
    if site && site.free?
      DEFAULT_FREE_EMAIL_THANK_YOU
    else
      DEFAULT_EMAIL_THANK_YOU
    end
  end

  def after_email_submit_action
    AFTER_EMAIL_ACTION_MAP[settings['after_email_submit_action']]
  end

  def email_redirect?
    after_email_submit_action == :redirect
  end

  def announcement?
    element_subtype == 'announcement'
  end

  def show_default_email_message?
    !site.capabilities.custom_thank_you_text? || (after_email_submit_action == :show_default_message)
  end

  def pushes_page_down
    nil
  end

  def image_style
    :modal
  end

  def statistics
    @statistics ||= FetchSiteStatistics.new(site, site_element_ids: [id]).call
  end

  private

  def email?
    element_subtype == 'email'
  end

  def site_is_capable_of_creating_element
    return unless site && site.capabilities.at_site_element_limit?

    errors.add(:site, 'is currently at its limit to create site elements')
  end

  def redirect_has_url
    return unless after_email_submit_action == :redirect

    if !site.capabilities.after_submit_redirect?
      errors.add('settings.redirect_url', 'is a pro feature')
    elsif settings['redirect_url'].blank?
      errors.add('settings.redirect_url', 'cannot be blank')
    end
  end

  def validate_thank_you_text
    return unless after_email_submit_action == :custom_thank_you_text

    if !site.capabilities.custom_thank_you_text?
      errors.add('custom_thank_you_text', 'is a pro feature')
    elsif self[:thank_you_text].blank?
      errors.add('custom_thank_you_text', 'cannot be blank')
    end
  end

  def custom_targeting?
    rule && rule.conditions.any?
  end

  def subscription_for_custom_targeting
    return unless custom_targeting? && !site.capabilities.custom_targeted_bars?
    errors.add(:site, 'subscription does not support custom targeting. Upgrade subscription.')
  end
end
