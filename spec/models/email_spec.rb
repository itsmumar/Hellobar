describe Email do
  it { is_expected.to validate_presence_of :from_name }
  it { is_expected.to validate_presence_of :from_email }
  it { is_expected.to validate_presence_of :subject }
  it { is_expected.to validate_presence_of :body }

  it { is_expected.to allow_value('abc@example.com').for :from_email }
  it { is_expected.not_to allow_value('example').for :from_email }
  it { is_expected.not_to allow_value('@example').for :from_email }

  it 'is a paranoia protected model', :freeze do
    Timecop.freeze(Time.current)

    email = create(:email)

    email.destroy

    expect(email).to be_persisted
    expect(email).to be_deleted
    expect(email.deleted_at).to eq Time.current

    Timecop.return
  end
end
