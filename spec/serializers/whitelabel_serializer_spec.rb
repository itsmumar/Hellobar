describe WhitelabelSerializer do
  let(:whitelabel) { create :whitelabel }
  let(:serializer) { WhitelabelSerializer.new(whitelabel) }

  it 'serializes whitelabel properties' do
    expect(serializer.as_json).to match(
      id: whitelabel.id,
      domain: whitelabel.domain,
      subdomain: whitelabel.subdomain,
      status: whitelabel.status,
      site_id: whitelabel.site_id,
      domain_identifier: whitelabel.domain_identifier,
      dns_records: whitelabel.dns_records
    )
  end
end
