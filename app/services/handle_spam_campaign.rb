class HandleSpamCampaign
  THREASHOLD_FOR_IS_PROCESSED = 0.9
  MAX_THREASHOLD_SENDING_SCORE = 60

  def initialize(campaign)
    @campaign = campaign
    @statistics = campaign.statistics
  end

  def call
    return if @statistics['recipients'].to_f.zero?
    @campaign.update_columns processed: processed?, spam: spam?
  end

  private

  def spam?
    campaign_sending_score >= MAX_THREASHOLD_SENDING_SCORE
  end

  def processed?
    processed_rate >= THREASHOLD_FOR_IS_PROCESSED
  end

  def processed_rate
    @statistics['submitted'].to_f / @statistics['recipients'].to_f
  end

  def campaign_sending_score
    (spam_report_rate + bounce_rate + unsubscribe_rate) / 3
  end

  def messages_sent
    @statistics['recipients'].to_f
  end

  def spam_report_rate
    (@statistics['reported'].to_f / messages_sent) * 100
  end

  def bounce_rate
    (@statistics['bounced'].to_f / messages_sent) * 100
  end

  def unsubscribe_rate
    (@statistics['unsubscribed'].to_f / messages_sent) * 100
  end
end
