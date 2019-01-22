class HandleSpamCampaign
  def initialize(campaign)
    @campaign = campaign
    @statistics = campaign.statistics
  end

  def call
    @campaign.update_columns processed: processed?, spam: spam?
  end

  private

  def spam?
    campaign_sending_score >= Campaign::MAX_THREASHOLD_SENDING_SCORE
  end

  def processed?
    @statistics['delivered'].to_f / @statistics['recipients'].to_f >= Campaign::THREASHOLD_FOR_IS_PROCESSED
  end

  def campaign_sending_score
    messages_sent = @statistics['recipients'].to_f # handling division by 0.
    spam_report_rate = (@statistics['reported'].to_f / messages_sent) * 100
    bounce_rate = (@statistics['bounced'].to_f / messages_sent) * 100
    unsubscribe_rate = (@statistics['unsubscribed'].to_f / messages_sent) * 100
    (spam_report_rate + bounce_rate + unsubscribe_rate) / 3
  end
end
