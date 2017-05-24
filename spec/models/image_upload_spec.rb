describe ImageUpload do
  it { should have_attached_file(:image) }
  it do
    should validate_attachment_content_type(:image)
      .allowing('image/png', 'image/jpeg', 'image/gif')
      .rejecting('text/plain', 'text/xml')
  end

  describe 'validations' do
    describe '#version' do
      let(:image_upload) { build(:image_upload, :with_valid_image) }

      it 'accepts version 1' do
        image_upload.version = 1

        expect(image_upload).to be_valid
      end

      it 'accepts version 2' do
        image_upload.version = 2

        expect(image_upload).to be_valid
      end

      context 'when version is 3' do
        before { image_upload.version = 3 }

        it 'does not accept version 3' do
          expect(image_upload).to_not be_valid
        end

        it 'sets an appropriate error message' do
          image_upload.valid?

          expect(image_upload.errors.to_h).to eq(version: 'is not included in the list')
        end
      end
    end
  end

  describe '#url' do
    let(:image_upload) { build(:image_upload, :with_valid_image, version: version) }

    subject { image_upload.url(style) }

    context 'when version is 1' do
      let(:version) { 1 }

      context 'when style is original' do
        let(:style) { :original }

        it 'returns the original URL' do
          expect(subject).to include 'original'
        end
      end

      # version 1 does not have large style
      context 'when style is large' do
        let(:style) { :large }

        it 'returns the original URL' do
          expect(subject).to include 'original'
        end
      end

      # version 1 does not have medium style
      context 'when style is medium' do
        let(:style) { :medium }

        it 'returns the original URL' do
          expect(subject).to include 'original'
        end
      end

      context 'when style is thumb' do
        let(:style) { :thumb }

        it 'returns the thumb URL' do
          expect(subject).to include 'thumb'
        end
      end
    end

    context 'when version is 2' do
      let(:version) { 2 }

      context 'when style is original' do
        let(:style) { :original }

        it 'returns the original URL' do
          expect(subject).to include 'original'
        end
      end

      # version 2 has large style
      context 'when style is large' do
        let(:style) { :large }

        it 'returns the large URL' do
          expect(subject).to include 'large'
        end
      end

      # version 2 has medium style
      context 'when style is medium' do
        let(:style) { :medium }

        it 'returns the medium URL' do
          expect(subject).to include 'medium'
        end
      end

      context 'when style is thumb' do
        let(:style) { :thumb }

        it 'returns the thumb URL' do
          expect(subject).to include 'thumb'
        end
      end
    end
  end
end
