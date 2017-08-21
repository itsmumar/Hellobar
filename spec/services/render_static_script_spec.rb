describe RenderStaticScript do
  let(:elements) { %i[traffic email facebook twitter] }
  let(:site) { create(:site, :with_user, :pro_managed, elements: elements) }
  let(:options) { {} }
  let(:service) { RenderStaticScript.new(site, options) }

  describe '#call' do
    let(:script) { service.call }

    it 'renders static script' do
      expect(StaticScriptAssets)
        .to receive(:render_model)
        .with(instance_of(StaticScriptModel))
        .and_return('__DATA__')

      expect(StaticScriptAssets)
        .to receive(:digest_path)
        .with('modules.js')
        .and_return('modules.js')

      expect(StaticScriptAssets)
        .to receive(:render)
        .with('static_script_template.js', site_id: site.id)
        .and_return('$INJECT_MODULES; $INJECT_DATA')

      expect(script).to eql '"/generated_scripts/modules.js"; __DATA__'
    end

    context 'when options[:compress]' do
      let(:options) { { compress: true } }

      it 'returns compressed script' do
        expect(StaticScriptAssets)
          .to receive(:render_model)
          .with(instance_of(StaticScriptModel))
          .and_return('__DATA__')

        allow(StaticScriptAssets)
          .to receive(:digest_path)
          .with('modules.js')
          .and_return 'modules.js'

        allow(StaticScriptAssets)
          .to receive(:render_compressed)
          .with('static_script_template.js', site_id: site.id)
          .and_return '$INJECT_MODULES; $INJECT_DATA'

        expect(service.call).to eql '"/generated_scripts/modules.js"; __DATA__'
      end
    end

    context 'when Settings.store_site_scripts_locally is false' do
      before do
        allow(StaticScriptAssets)
          .to receive(:render_model)
          .with(instance_of(StaticScriptModel))
          .and_return('__DATA__')

        allow(StaticScriptAssets)
          .to receive(:digest_path)
          .with('modules.js')
          .and_return 'modules.js'

        allow(service)
          .to receive(:render_asset)
          .with('static_script_template.js')
          .and_return '$INJECT_MODULES; $INJECT_DATA'
      end

      before { allow(Settings).to receive(:store_site_scripts_locally).and_return false }

      context 'and Settings.script_cdn_url presents' do
        before { allow(Settings).to receive(:script_cdn_url).and_return 'cdn.com' }
        before { allow(Settings).to receive(:s3_bucket).and_return '' }

        it 'renders script cdn url to modules.js' do
          expect(service.call)
            .to eql '"https://cdn.com/modules.js"; __DATA__'
        end
      end

      context 'and Settings.s3_bucket presents' do
        before { allow(Settings).to receive(:s3_bucket).and_return 's3_bucket' }
        before { allow(Settings).to receive(:script_cdn_url).and_return '' }

        it 'renders script cdn url to modules.js' do
          expect(service.call)
            .to eql '"https://s3.amazonaws.com/s3_bucket/modules.js"; __DATA__'
        end
      end

      context 'otherwise' do
        before { allow(Settings).to receive(:s3_bucket).and_return '' }
        before { allow(Settings).to receive(:script_cdn_url).and_return '' }

        it 'raises error' do
          expect { service.call }
            .to raise_error 'Could not determine url for modules.js'
        end
      end
    end

    context 'with custom html/js' do
      let(:custom_html) { '<script>alert(1)</script>' }
      let!(:site_element) { create(:site_element, :custom, custom_html: custom_html, site: site) }

      before do
        allow(service)
          .to receive(:render_asset)
          .with('static_script_template.js')
          .and_return('$INJECT_DATA; $INJECT_MODULES')

        allow_any_instance_of(SiteElement)
          .to receive(:statistics).and_return(SiteStatistics.new)
      end

      it 'escapes </script>' do
        expect(service.call).to include '"custom_html":"\u003cscript\u003ealert(1)\u003c/script\u003e",'
      end
    end
  end
end
