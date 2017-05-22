require 'zlib'

describe UploadToS3 do
  let(:filename) { 'test.js' }
  let(:contents) { 'contents' }
  let(:bucket) { 'foobar' }
  let(:s3_double) { double(:s3_double, put_object: true) }

  let(:service) { described_class.new(filename, contents, bucket) }

  before { allow(service).to receive(:s3_bucket).and_return(s3_double) }

  subject { service.call }

  describe '#initialize' do
    context 'when no bucket is defined' do
      let(:bucket) { nil }

      it 'defaults to Settings.s3_bucket' do
        expect(service.bucket).to eq Settings.s3_bucket
      end
    end

    context 'when a bucket is defined' do
      it 'uses the provided bucket' do
        expect(service.bucket).to eq bucket
      end
    end
  end

  describe '#call' do
    it 'calls put_object' do
      subject

      expect(s3_double).to have_received(:put_object).with(
        key: 'test.js',
        body: service.compressed_contents,
        acl: 'public-read',
        content_type: 'text/javascript',
        content_encoding: 'gzip',
        metadata: {
          'Cache-Control' => 'max-age=120,s-maxage=5'
        }
      )
    end
  end
end
