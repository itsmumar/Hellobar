class PostToSlack
  include HTTParty
  base_uri 'https://hooks.slack.com/services/'

  def initialize(channel, level: :info, text:)
    raise 'invalid level' unless level.in?(%i[success error info])

    @channel = Settings.slack_channels.fetch(channel.to_s)
    @level = level
    @text = text
  end

  def call
    send level, text
  end

  private

  attr_reader :channel, :level, :text

  def success(text)
    post attachments: [{ color: 'good', text: text }]
  end

  def error(text)
    post attachments: [{ color: 'danger', text: text }]
  end

  def info(text)
    post text: text
  end

  def post(payload)
    self.class.post uri, body: { payload: payload.to_json }
  end

  # make correct URI for all cases
  #   'services/' + '/channel' #=> 'services/channel'
  #   'services' + 'channel'   #=> 'services/channel'
  def uri
    @uri ||= File.join(self.class.base_uri, channel)
  end
end
