class SiteElement < ApplicationRecord
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
  validate :ensure_custom_targeting_allowed
  validate :ensure_precise_geolocation_targeting_allowed
  validate :ensure_closable_allowed
  validate :ensure_custom_thank_you_text_allowed, if: :email?
  validate :ensure_custom_thank_you_text_configured, if: :email?
  validate :ensure_custom_redirect_url_allowed, if: :email?
  validate :ensure_custom_redirect_url_configured, if: :email?

  scope :paused, -> { where("paused = true and type != 'ContentUpgrade'") }
  scope :active, -> { where("paused = false and type != 'ContentUpgrade'") }
  scope :paused_content_upgrades, -> { where("paused = true and type = 'ContentUpgrade'") }
  scope :active_content_upgrades, -> { where("paused = false and type = 'ContentUpgrade'") }
  scope :content_upgrades, -> { where("type = 'ContentUpgrade'") }
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

  after_destroy :nullify_image_upload_reference

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

  QUESTION_DEFAULTS.each_key do |attr_name|
    define_method attr_name do
      self[attr_name].presence || QUESTION_DEFAULTS[attr_name] if use_question?
    end
  end

  def self.types
    [Bar, Modal, Slider, Takeover, ContentUpgrade, Alert].map(&:name)
  end

  def caption=(value)
    self[:caption] = sanitize value
  end

  def headline=(value)
    value = sanitize value
    value = 'Hello. Add your message here.' if value.blank?
    self[:headline] = value
  end

  def link_text=(value)
    self[:link_text] = sanitize value
  end

  def content=(value)
    self[:content] = sanitize value
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
    update! paused: !paused?
  end

  def short_subtype
    element_subtype[/(\w+)/]
  end

  def self.all_templates
    [].tap do |templates|
      types.each do |type|
        BAR_TYPES.each_key do |subtype|
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
    if site&.free?
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

  def custom_thank_you?
    after_email_submit_action == :custom_thank_you_text
  end

  def redirect_url
    settings['redirect_url']
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
    return unless site&.capabilities&.at_site_element_limit?

    errors.add(:site, 'is currently at its limit to create site elements')
  end

  def custom_targeting?
    rule&.conditions&.any?
  end

  def precise_geolocation_targeting?
    rule&.conditions&.any?(&:precise?)
  end

  def ensure_closable_allowed
    return if paused? || !closable? || site.capabilities.closable?

    errors.add(:site, 'subscription does not support closable elements. Upgrade subscription.')
  end

  def ensure_custom_targeting_allowed
    return if paused? || !custom_targeting? || site.capabilities.custom_targeted_bars?

    errors.add(:site, 'subscription does not support custom targeting. Upgrade subscription.')
  end

  def ensure_precise_geolocation_targeting_allowed
    return if paused? || !precise_geolocation_targeting? || site.capabilities.precise_geolocation_targeting?

    errors.add(:site, 'subscription does not support precise geolocation targeting. Upgrade subscription.')
  end

  def ensure_custom_thank_you_text_allowed
    return if paused? || !custom_thank_you? || site.capabilities.custom_thank_you_text?

    errors.add(:thank_you_text, 'subscription does not support custom thank you text. Upgrade subscription.')
  end

  def ensure_custom_thank_you_text_configured
    return if !custom_thank_you? || thank_you_text.present?

    errors.add(:thank_you_text, :blank)
  end

  def ensure_custom_redirect_url_allowed
    return if paused? || !email_redirect? || site.capabilities.after_submit_redirect?

    errors.add(:redirect_url, 'subscription does not support custom redirect URL. Upgrade subscription.')
  end

  def ensure_custom_redirect_url_configured
    return if !email_redirect? || redirect_url.present?

    errors.add(:redirect_url, :blank)
  end

  def nullify_image_upload_reference
    # When marking site element as deleted, it will not be able to nullify the
    # active_image_id reference when ImageUpload record is destroyed
    # This is a Paranoia issue, which we need to work around manually
    # https://github.com/rubysherpas/paranoia/issues/413
    update_attribute :active_image_id, nil
  end

  def sanitize(value)
    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    white_list_sanitizer.sanitize(value, tags: WHITELISTED_TAGS, attributes: WHITELISTED_ATTRS)
  end
end
