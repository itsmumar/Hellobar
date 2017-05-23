require 'zlib'

describe UploadToS3 do
  let(:filename) { 'test.js' }
  let(:contents) { 'contents' }
  let(:bucket) { 'foobar' }
  let(:s3_double) { double(:s3_double, put_object: true) }

  let(:service) { described_class.new(filename, contents, bucket) }

  before { allow(Aws::S3::Bucket).to receive(:new).and_return(s3_double) }

  describe '#call' do
    before { service.call }

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

    context 'when no bucket is defined' do
      let(:bucket) { nil }

      it 'defaults to Settings.s3_bucket' do
        expect(Aws::S3::Bucket).to have_received(:new).with(Settings.s3_bucket)
      end
    end
  end
end
