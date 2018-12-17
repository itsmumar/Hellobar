describe CsvUpload do
  it { is_expected.to have_attached_file :csv }

  it 'validates content-type' do
    is_expected
      .to validate_attachment_content_type(:csv)
      .allowing('text/csv', 'text/plain')
  end

  describe '#file' do
    let(:csv_upload) { build :csv_upload }

    it 'returns a readable object' do
      expect(csv_upload.file).to respond_to :read
      expect(csv_upload.file.read)
        .to eql Rails.root.join('spec', 'fixtures', 'subscribers.csv').read
    end
  end
end
