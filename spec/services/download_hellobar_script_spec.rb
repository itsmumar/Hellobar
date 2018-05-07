describe DownloadHellobarScript do
  let(:filename) { StaticScript::HELLOBAR_SCRIPT_NAME }
  let(:script_content) { 'script content' }

  let(:s3_object_body) { StringIO.new(script_content) }
  let(:s3_object) do
    instance_double(Aws::S3::Types::GetObjectOutput, body: s3_object_body)
  end
  let(:s3) { instance_double(Aws::S3::Client) }
  let(:file) { double(File) }

  let(:path) { File.join(StaticScript::SCRIPTS_LOCAL_FOLDER, filename) }
  let(:local_path) { Rails.root.join(path) }

  let(:service) { described_class.new }

  before do
    DownloadHellobarScript.logger = nil
    allow(Aws::S3::Client).to receive(:new).and_return(s3)
    allow(Rails)
      .to receive_message_chain(:root, :join)
      .with('public', 'generated_scripts', filename)
      .and_return(local_path)
  end

  context 'when file exists' do
    before do
      allow(local_path).to receive(:exist?).and_return(true)
    end

    it 'does nothing' do
      expect(File).not_to receive(:open)
      service.call
    end
  end

  context 'when file does not exist' do
    before do
      allow(local_path).to receive(:exist?).and_return(false)
    end

    it 'downloads and stores file in public/generated_scripts' do
      expect(file).to receive(:puts).with(script_content)
      expect(File)
        .to receive(:open)
        .with(pathname_ending_with(path), 'wb')
        .and_yield(file)

      expect(s3)
        .to receive(:get_object)
        .with(bucket: Settings.s3_bucket, key: filename)
        .and_return(s3_object)

      service.call
    end
  end
end
