describe StaticScript do
  let(:site) { create :site }
  let(:script) { StaticScript.new(site) }

  describe '#hashed_id' do
    it 'returns hashed site id' do
      expect(script.hashed_id).to eql Digest::SHA1.hexdigest("bar#{ site.id }cat")
    end
  end

  describe '#name' do
    it 'returns hashed site id with .js extension' do
      expect(script.name).to eql Digest::SHA1.hexdigest("bar#{ site.id }cat") + '.js'
    end
  end

  describe '#url' do
    context 'when Settings.store_site_scripts_locally is true' do
      before { allow(Settings).to receive(:store_site_scripts_locally).and_return true }

      it 'returns a path to local file' do
        expect(script.url).to eql "/generated_scripts/#{ script.name }"
      end
    end

    context 'when Settings.store_site_scripts_locally is false' do
      before { allow(Settings).to receive(:store_site_scripts_locally).and_return false }

      context 'and Settings.script_cdn_url presents' do
        before { allow(Settings).to receive(:script_cdn_url).and_return 'cdn.com' }

        it 'returns an url to cdn host with https protocol' do
          expect(script.url).to eql "https://cdn.com/#{ script.name }"
        end
      end

      context 'and Settings.script_cdn_url does not present' do
        before { allow(Settings).to receive(:script_cdn_url).and_return '' }

        it 'raises error' do
          expect { script.url }
            .to raise_error 'Settings.script_cdn_url or Settings.store_site_scripts_locally must be set'
        end
      end
    end
  end

  describe '#modules_url' do
    context 'when Settings.store_site_scripts_locally is true' do
      before { allow(Settings).to receive(:store_site_scripts_locally).and_return true }

      it 'returns a path to local file' do
        expect(script.modules_url).to start_with '/generated_scripts/modules-'
      end
    end

    context 'when Settings.store_site_scripts_locally is false' do
      before { allow(Settings).to receive(:store_site_scripts_locally).and_return false }

      context 'and Settings.script_cdn_url presents' do
        before { allow(Settings).to receive(:script_cdn_url).and_return 'cdn.com' }

        it 'returns an url to cdn host with https protocol' do
          expect(script.modules_url).to start_with 'https://cdn.com/modules-'
        end
      end

      context 'and Settings.script_cdn_url does not present' do
        before { allow(Settings).to receive(:script_cdn_url).and_return '' }

        it 'raises error' do
          expect { script.modules_url }
            .to raise_error 'Settings.script_cdn_url or Settings.store_site_scripts_locally must be set'
        end
      end
    end
  end

  describe '#generate' do
    it 'enqueues GenerateStaticScriptJob' do
      expect { script.generate }.to have_enqueued_job GenerateStaticScriptJob
    end

    context 'when development' do
      before { allow(Rails.env).to receive(:development?).and_return true }

      it 'generates test site' do
        full_path = Rails.root.join('public/test_site.html')

        expect(GenerateTestSite)
          .to receive_service_call
          .with(site.id, full_path: full_path)

        script.generate
      end
    end
  end

  describe '#installed?' do
    it 'calls CheckStaticScriptInstallation' do
      expect(CheckStaticScriptInstallation).to receive_service_call.with(site)
      script.installed?
    end

    context 'when script_installed_at is present' do
      before { expect(CheckStaticScriptInstallation).to receive_service_call.with(site) }

      context 'and script_uninstalled_at is blank' do
        let(:site) { create(:site, script_installed_at: Time.current, script_uninstalled_at: nil) }
        specify { expect(script.installed?).to be_truthy }
      end

      context 'and script_installed_at > script_uninstalled_at' do
        let(:site) { create(:site, script_installed_at: Time.current, script_uninstalled_at: 1.day.ago) }
        specify { expect(script.installed?).to be_truthy }
      end
    end

    context 'when script_installed_at is blank' do
      before { expect(CheckStaticScriptInstallation).to receive_service_call.with(site) }
      let(:site) { create(:site, script_installed_at: nil) }

      specify { expect(script.installed?).to be_falsey }
    end
  end

  describe '#destroy' do
    it 'calls GenerateAndStoreStaticScript' do
      expect(GenerateAndStoreStaticScript)
        .to receive_service_call
        .with(site, script_content: '')

      script.destroy
    end
  end
end
