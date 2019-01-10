class UploadImageToS3
  def initialize(photo)
    @photo = photo
    @uploaded_image = nil
  end

  def call
    @uploaded_image = s3_bucket.put_object(key: key_path,
                      body: File.read(@photo.tempfile),
                      acl: 'public-read',
                      content_type: @photo.content_type)
    cloud_front_url
  end

  def cloud_front_url
    "https://#{ Settings.s3_campaign_bucket }/#{ @uploaded_image.key }"
  end

  def key_path
    "emails/#{ Date.current.strftime('%m-%d-%y') }/#{ Time.current.to_i }-#{ @photo.original_filename }"
  end

  def s3_bucket
    Aws::S3::Bucket.new(Settings.s3_campaign_bucket)
  end
end
