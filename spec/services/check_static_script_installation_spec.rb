describe CheckStaticScriptInstallation do
  describe '#call' do
    it 'calls SendSnsNotification with appropriate message' do
      site_element_ids = [1, 2, 3]
      site_elements = double 'Site Elements', pluck: site_element_ids

      script_name = 'script.js'

      site = instance_double Site,
        id: 1,
        url: 'http://localhost',
        script_name: script_name,
        site_elements: site_elements

      message_hash = {
        environment: 'test',
        scriptName: script_name,
        siteElementIds: site_element_ids,
        siteId: site.id,
        siteUrl: site.url
      }

      expect(SendSnsNotification).to receive_service_call
        .with(
          a_hash_including(
            topic_arn: a_string_matching(/arn:aws:sns:.+_latest/),
            subject: a_string_matching('installCheck'),
            message_hash: message_hash
          )
        )

      CheckStaticScriptInstallation.new(site).call
    end
  end
end
