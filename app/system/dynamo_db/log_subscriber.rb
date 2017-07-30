class DynamoDB::LogSubscriber < ActiveSupport::LogSubscriber
  def query(event)
    payload = event.payload
    message = [
      title(event),
      capacity(payload),
      request(payload)
    ]

    debug "  #{ message.compact.join(' ') }"
  end

  private

  def title(event)
    color(
      "DynamoDB #{ event.payload[:method].to_s.humanize.titlecase } (#{ event.duration.round(1) }ms)",
      :blue,
      true
    )
  end

  def request(payload)
    color(payload[:request], nil, false)
  end

  def capacity(payload)
    return unless payload[:consumed_capacity]
    Array.wrap(payload[:consumed_capacity]).map { |consumed_capacity|
      color(
        "[#{ consumed_capacity.table_name } #{ consumed_capacity.capacity_units }]",
        :green,
        false
      )
    }.join(' ')
  end
end
