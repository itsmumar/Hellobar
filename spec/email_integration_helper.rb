def record_mailer_gateway_request_history!
  @email_history = {}

  stub = MailerGateway.stub(:send_email) do |type, recipient, _params|
    date = Time.zone.today
    ((@email_history[date] ||= {})[recipient] ||= []) << type
  end
  stub.and_return(true)
end

def day_from_current_spec_description
  example.metadata[:description].match(/\d*$/).to_s.to_i
end

def expect_no_email(user)
  @email_history.each do |_date, messages|
    expect(messages).not_to include(user.email)
  end
end

def expect_user_to_only_recieve(user, email_type)
  expect(@email_history.size).to eq 1
  expect(@email_history.first).to include(user.email => [email_type])
end

def email_received_a_number_of_days_after(user, start_date, date_index = day_from_current_spec_description)
  date = start_date + date_index
  ((@email_history[date] ||= {})[user.email] ||= [])
end
