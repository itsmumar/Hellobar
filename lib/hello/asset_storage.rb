require 'zlib'
require 'stringio'

module Hello
  class AssetStorage
    MAXAGE = 2.minutes
    S_MAXAGE = 5.seconds

    attr_accessor :bucket

    def initialize(bucket = nil)
      @bucket = bucket || Settings.s3_bucket
    end

    def create_or_update_file_with_contents(filename, contents)
      compressed = StringIO.new('', 'w')
      gz = Zlib::GzipWriter.new(compressed)
      gz.write(contents)
      gz.close
      contents = compressed.string

      s3_bucket.put_object(
        key: filename,
        body: contents,
        acl: 'public-read',
        content_type: 'text/javascript',
        content_encoding: 'gzip',
        metadata: cache_header
      )
    end

    def cache_header
      { 'Cache-Control' => "max-age=#{ MAXAGE },s-maxage=#{ S_MAXAGE }" }
    end

    private

    def s3_bucket
      @s3_bucket ||= Aws::S3::Bucket.new(@bucket)
    end
  end
end
