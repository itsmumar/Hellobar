describe CustomPaperclip do
  describe '#save' do
    it 'returns false if photo is blank' do
      custom = CustomPaperclip::UploadImage.new
      expect(custom.save).to eql false
    end
  end
end
