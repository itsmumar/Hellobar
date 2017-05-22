require 'zlib'
require 'stringio'

class UploadToS3
  MAXAGE = 2.minutes
  S_MAXAGE = 5.seconds

  attr_reader :bucket

  # @param [String] filename
  # @param [String] contents
  # @param [String] bucket
  def initialize(filename, contents, bucket = nil)
    @filename = filename
    @contents = contents
    @bucket = bucket || Settings.s3_bucket
  end

  def call
    s3_bucket.put_object(
      key: @filename,
      body: compressed_contents,
      acl: 'public-read',
      content_type: 'text/javascript',
      content_encoding: 'gzip',
      metadata: cache_header
    )
  end

  def compressed_contents
    compressed = StringIO.new('', 'w')

    gz = Zlib::GzipWriter.new(compressed)
    gz.write(@contents)
    gz.close

    compressed.string
  end

  private

  def cache_header
    { 'Cache-Control' => "max-age=#{ MAXAGE },s-maxage=#{ S_MAXAGE }" }
  end

  def s3_bucket
    Aws::S3::Bucket.new(@bucket)
  end
end
