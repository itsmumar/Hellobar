describe PrepareZippedContacts do
  let(:contact_list) { create :contact_list }
  let(:service) { PrepareZippedContacts.new(contact_list) }
  let(:csv_content) { 'csv' }

  before do
    expect(FetchContactsCSV)
      .to receive_service_call.with(contact_list).and_return(csv_content)
  end

  def extract(zip_file)
    zip = Zip::InputStream.open(StringIO.new(zip_file))
    entry = zip.get_next_entry
    entry.get_input_stream.read
  end

  it 'returns zip file' do
    expect(extract(service.call)).to eql csv_content
  end
end
