require 'zlib'
require 'stringio'

module Hello
  class AssetStorage
    MAXAGE = 2.minutes
    S_MAXAGE = 5.seconds

    cattr_accessor :connection

    self.connection = Fog::Storage.new({
      provider:               'AWS',
      aws_access_key_id:      Hellobar::Settings[:aws_access_key_id] || 'fake_access_key_id',
      aws_secret_access_key:  Hellobar::Settings[:aws_secret_access_key] || 'fake_secret_access_key',
      path_style: true
    })

    attr_accessor :directory

    def initialize(directory = nil)
      if directory.is_a?(String)
        directory = self.class.connection.directories.get(directory)
      end

      @directory = directory || self.class.connection.directories.get(Hellobar::Settings[:s3_bucket])

      @directory ||= self.connection.directories.create(:key => 'test')
    end

    def create_or_update_file_with_contents(filename, contents)
      compressed = StringIO.new('', 'w')
      gz = Zlib::GzipWriter.new(compressed)
      gz.write(contents)
      gz.close
      contents = compressed.string

      file = directory.files.get(filename)

      if file
        file.body = contents
        file.public = true
        file.content_type = 'text/javascript'
        file.content_encoding = 'gzip'
        file.metadata = cache_header
      else
        file = directory.files.new({
          :key => filename,
          :body => contents,
          :public => true,
          :content_type => 'text/javascript',
          :content_encoding => 'gzip',
          :metadata => cache_header
        })
      end

      file.save
      file
    end

    def cache_header
      {'Cache-Control' => "max-age=#{MAXAGE},s-maxage=#{S_MAXAGE}"}
    end
  end
end
