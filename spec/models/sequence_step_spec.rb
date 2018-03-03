describe SequenceStep do
  it { is_expected.to validate_presence_of :delay }

  it 'is a paranoia protected model', :freeze do
    sequence_step = create :sequence_step

    sequence_step.destroy

    expect(sequence_step).to be_persisted
    expect(sequence_step).to be_deleted
    expect(sequence_step.deleted_at).to eq Time.current
  end
end
