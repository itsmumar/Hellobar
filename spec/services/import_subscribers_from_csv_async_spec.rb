describe ImportSubscribersFromCsvAsync do
  let(:contact_list) { create :contact_list }
  let(:uploaded_file) { Rails.root.join('spec', 'fixtures', 'subscribers.csv').open }
  let(:service) { ImportSubscribersFromCsvAsync.new(uploaded_file, contact_list) }

  it 'creates CsvUpload' do
    expect { service.call }
      .to change(CsvUpload, :count)
      .by(1)
  end

  it 'calls ImportSubscribersFromCsvJob' do
    expect { service.call }
      .to have_enqueued_job(ImportSubscribersFromCsvJob)
      .with(instance_of(CsvUpload))
  end
end
