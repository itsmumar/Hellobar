describe AmplitudeSerializer do
  let!(:user) { create :user }
  let!(:site) { create :site, user: user, url: 'яндекс.рф' }
  let(:serializer) { AmplitudeSerializer.new(user) }

  it 'serializes user properties' do
    expect(serializer.as_json).to match(
      user_id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      primary_domain: Addressable::URI.parse(site.url).normalized_host
    )
  end
end
