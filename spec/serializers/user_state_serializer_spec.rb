describe ApiSerializer::UserStateSerializer do
  let(:user) { create :user, :with_credit_card, :with_email_bar }
  let(:serializer) { ApiSerializer::UserStateSerializer.new(user) }

  it 'serializes user' do
    expect(serializer.serializable_hash).to include(
      :user, :sites, :site_memberships, :rules, :site_elements, :credit_cards
    )
  end
end
