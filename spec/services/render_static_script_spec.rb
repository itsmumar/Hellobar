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
        .with('static_script_template.js', site_id: site.id)
        .and_return('$INJECT_MODULES; $INJECT_DATA')

      folder = StaticScript::SCRIPTS_LOCAL_FOLDER
      filename = HellobarModules.filename
      expect(script).to eql %("#{ folder }#{ filename }"; __DATA__)
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

        folder = StaticScript::SCRIPTS_LOCAL_FOLDER
        filename = HellobarModules.filename
        expect(script).to eql %("#{ folder }#{ filename }"; __DATA__)
      end
    end
  end
end
