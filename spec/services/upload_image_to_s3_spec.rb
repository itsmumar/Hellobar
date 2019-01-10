describe UploadImageToS3 do
  let(:url) { 'valid-url' }
  let(:photo) { fixture_file_upload('photo.jpg', 'application/jpg') }

  describe '#call' do
    before do
      stub_request(:put, /.*/).to_return(status: 200, body: '', headers: {})
    end

    it 'returns url with current date in the URL' do
      url = UploadImageToS3.new(photo).call
      expect(url).to include(Date.current.strftime('%m-%d-%y').to_s)
    end

    it 'returns a valid URL' do
      url = UploadImageToS3.new(photo).call
      expect(url).to match(/https?:\/\/[\S]+/)
    end
  end
end
