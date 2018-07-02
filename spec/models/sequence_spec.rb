describe Sequence do
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :contact_list }

  it 'is a paranoia protected model', :freeze do
    sequence = create :sequence

    sequence.destroy

    expect(sequence).to be_persisted
    expect(sequence).to be_deleted
    expect(sequence.deleted_at).to eq Time.current
  end
end
