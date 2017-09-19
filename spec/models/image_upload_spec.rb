describe ImageUpload do
  it { is_expected.to have_attached_file :image }

  it 'validates content-type' do
    is_expected.to validate_attachment_content_type(:image)
      .allowing('image/png', 'image/jpeg', 'image/gif')
      .rejecting('text/plain', 'text/xml')
  end

  describe '#url' do
    let(:image_upload) { build :image_upload, :with_valid_image }

    ImageUpload::STYLES.keys.each do |style|
      context "when style is :#{ style }" do
        it "returns #{ style } url" do
          expect(image_upload.url(style)).to include style.to_s
        end
      end
    end
  end

  ImageUpload::STYLES.keys.each do |style|
    describe "##{ style }_url" do
      let(:image_upload) { build(:image_upload, :with_valid_image) }

      it "returns the #{ style } URL" do
        expect(image_upload.send("#{ style }_url")).to include style.to_s
      end
    end
  end
end
