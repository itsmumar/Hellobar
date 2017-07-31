describe PrepareZippedContacts do
  let(:contact_list) { create :contact_list }
  let(:filename) { 'filename.csv' }
  let(:service) { PrepareZippedContacts.new(contact_list, filename) }
  let(:csv_content) { 'csv' }
  let(:extracted_entry) { extract_entry(service.call) }
  let(:extracted_content) { extracted_entry.get_input_stream.read }

  before do
    expect(FetchContactsCSV)
      .to receive_service_call.with(contact_list).and_return(csv_content)
  end

  def extract_entry(zip_file)
    zip = Zip::InputStream.open(StringIO.new(zip_file))
    zip.get_next_entry
  end

  it 'returns zip file' do
    expect(extracted_entry.name).to eql filename
    expect(extracted_content).to eql csv_content
  end
end
