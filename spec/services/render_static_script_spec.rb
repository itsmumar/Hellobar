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
        .to receive(:render)
        .with('modules.js', site_id: site.id)
        .and_return('__MODULES__')

      expect(StaticScriptAssets)
        .to receive(:render)
        .with('static_script_template.js', site_id: site.id)
        .and_return('$INJECT_MODULES; $INJECT_DATA')

      expect(script).to eql '__MODULES__; __DATA__'
    end

    context 'when options[:compress]' do
      let(:options) { { compress: true } }

      it 'returns compressed script' do
        expect(StaticScriptAssets)
          .to receive(:render_model)
          .with(instance_of(StaticScriptModel))
          .and_return('__DATA__')

        allow(StaticScriptAssets)
          .to receive(:render_compressed)
          .with('modules.js', site_id: site.id)
          .and_return 'compressed_modules.js'

        allow(StaticScriptAssets)
          .to receive(:render_compressed)
          .with('static_script_template.js', site_id: site.id)
          .and_return '$INJECT_MODULES; $INJECT_DATA'

        expect(service.call).to eql 'compressed_modules.js; __DATA__'
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

        allow(service)
          .to receive(:render_asset)
          .with('modules.js')
          .and_return('MODULES')
      end

      it 'escapes </script>' do
        expect(service.call).to include '"custom_html":"\u003cscript\u003ealert(1)\u003c/script\u003e",'
      end
    end
  end
end
