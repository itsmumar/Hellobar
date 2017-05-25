require 'zlib'
require 'stringio'

class UploadToS3
  MAXAGE = 1.day
  S_MAXAGE = 10.seconds

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
      cache_control: cache_header
    )
  end

  private

  def compressed_contents
    compressed = StringIO.new('', 'w')

    gz = Zlib::GzipWriter.new(compressed)
    gz.write(@contents)
    gz.close

    compressed.string
  end

  def cache_header
    "must-revalidate, proxy-revalidate, max-age=#{ MAXAGE }, s-maxage=#{ S_MAXAGE }"
  end

  def s3_bucket
    Aws::S3::Bucket.new(@bucket)
  end
end
