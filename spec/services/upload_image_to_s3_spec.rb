describe UploadImageToS3 do
  let(:url) { 'valid-url' }

  describe '#call' do
    before do
      allow_any_instance_of(Paperclip::Attachment).to receive(:save).and_return(url)
    end

    it 'returns false if photo is blank' do
      service = UploadImageToS3.new(photo: nil)
      expect(service.call).to eql false
    end

    it 'returns url for a successful photo upload' do
      photo = fixture_file_upload('photo.jpg', 'application/jpg')
      url = UploadImageToS3.new(photo: photo).call
      expect(url).to eql url
    end
  end
end
