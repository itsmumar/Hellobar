require 'zlib'
require 'stringio'

class UploadToS3
  MAXAGE = 1.day
  S_MAXAGE = 10.seconds

  # @param [String] filename
  # @param [String] contents
  # @param [Integer] maxage
  def initialize(filename, contents, cache: nil)
    @filename = filename
    @contents = contents
    @maxage = cache || MAXAGE
    @s_maxage = cache || S_MAXAGE
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

  # @see https://www.mnot.net/cache_docs/#PROXY
  # *must-revalidate* - tells caches that they must obey any freshness information you give them about a representation.
  # *max-age* - specifies the maximum amount of time that a representation will be considered fresh
  # *s-maxage* - similar to max-age, except that it only applies to shared (e.g., proxy or CloudFront) caches
  # with this configuration CloudFront will be refreshing cache every 10 seconds
  # but end user will be getting more often 304 or 200 (cached in CloudFront) version during a day
  def cache_header
    "must-revalidate, proxy-revalidate, max-age=#{ @maxage }, s-maxage=#{ @s_maxage }"
  end

  def s3_bucket
    Aws::S3::Bucket.new(Settings.s3_bucket)
  end
end
