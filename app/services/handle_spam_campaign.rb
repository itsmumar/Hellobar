class HandleSpamCampaign
  THREASHOLD_FOR_IS_PROCESSED = 0.9
  MAX_THREASHOLD_SPAM_SCORE = 30
  MAX_THREASHOLD_BOUNCE_RATE = 50

  def initialize(campaign)
    @campaign = campaign
  end

  def call
    return if messages_sent.zero?
    campaign.update_columns processed: processed?, spam: spam?
  end

  private

  attr_reader :campaign

  def spam?
    bounce_rate >= MAX_THREASHOLD_BOUNCE_RATE || spam_score >= MAX_THREASHOLD_SPAM_SCORE
  end

  def processed?
    processed_rate >= THREASHOLD_FOR_IS_PROCESSED
  end

  def processed_rate
    statistics['submitted'].to_f / messages_sent
  end

  def spam_score
    (reported_and_unsubscribed / statistics['delivered'].to_f) * 100
  end

  def reported_and_unsubscribed
    statistics['reported'].to_f + statistics['unsubscribed'].to_f
  end

  def messages_sent
    statistics['recipients'].to_f
  end

  def bounce_rate
    (statistics['bounced'].to_f / messages_sent) * 100
  end

  def statistics
    campaign.statistics
  end
end
