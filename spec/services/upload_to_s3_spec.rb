require 'zlib'

describe UploadToS3 do
  let(:filename) { 'test.js' }
  let(:contents) { 'contents' }
  let(:bucket) { 'foobar' }
  let(:s3_double) { double(:s3_double, put_object: true) }

  let(:service) { described_class.new(filename, contents) }

  before do
    allow(Aws::S3::Bucket)
      .to receive(:new)
      .with(Settings.s3_bucket)
      .and_return(s3_double)
  end

  describe '#call' do
    before { service.call }

    it 'calls put_object' do
      expect(s3_double).to have_received(:put_object).with(
        hash_including(
          key: 'test.js',
          acl: 'public-read',
          content_type: 'text/javascript',
          content_encoding: 'gzip',
          cache_control: 'must-revalidate, proxy-revalidate, max-age=86400, s-maxage=10'
        )
      )
    end
  end
end
