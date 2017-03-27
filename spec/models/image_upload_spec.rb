describe ImageUpload do
  it { should have_attached_file(:image) }
  it do
    should validate_attachment_content_type(:image)
      .allowing('image/png', 'image/jpeg', 'image/gif')
      .rejecting('text/plain', 'text/xml')
  end
end
