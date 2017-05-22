describe Hello::AssetStorage do
  let(:bucket) { 'foobar' }
  let(:asset_storage) { described_class.new(bucket) }

  describe '#initialize' do
    context 'when no bucket is defined' do
      let(:bucket) { nil }

      it 'defaults to Settings.s3_bucket' do
        expect(asset_storage.bucket).to eq Settings.s3_bucket
      end
    end

    context 'when a bucket is defined' do
      it 'uses the provided bucket' do
        expect(asset_storage.bucket).to eq bucket
      end
    end
  end

  describe '#create_or_update_file_with_contents' do
    let(:s3_double) { double(:s3_double, put_object: true) }

    before do
      allow(asset_storage).to receive(:s3_bucket).and_return(s3_double)

      asset_storage.create_or_update_file_with_contents('test.js', 'contents')
    end

    it 'calls put_object' do
      expect(s3_double).to have_received(:put_object).with(
        hash_including(
          key: 'test.js',
          acl: 'public-read',
          content_type: 'text/javascript',
          content_encoding: 'gzip',
          metadata: {
            'Cache-Control' => 'max-age=120,s-maxage=5'
          }
        )
      )
    end
  end
end
