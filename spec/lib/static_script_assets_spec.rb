describe StaticScriptAssets do
  let(:assets) { described_class }

  describe '.uglifier' do
    it 'returns an instance of Uglifier' do
      expect(assets.uglifier).to be_a Uglifier
    end
  end

  describe '.jbuilder' do
    it 'returns instance of ActionView::Base' do
      expect(assets.jbuilder).to be_a ActionView::Base
    end
  end

  describe '.env' do
    it 'returns instance of Sprockets::Environment' do
      expect(assets.env).to be_a Sprockets::Environment
    end
  end

  describe '.manifest' do
    it 'returns instance of Sprockets::Manifest' do
      expect(assets.manifest).to be_a Sprockets::Manifest
    end

    it 'associated with env' do
      expect(assets.manifest.environment).to eql assets.env
    end
  end

  describe '.precompile' do
    let(:manifest) { double('manifest') }

    before do
      allow(assets).to receive(:manifest).and_return(manifest)
      allow(manifest).to receive(:clobber)
      allow(manifest).to receive(:compile)
    end

    it 'cleans up precompiled assets' do
      assets.precompile
      expect(manifest).to have_received(:clobber)
    end

    it 'precompiles all static script assets' do
      assets.precompile
      expect(manifest).to have_received(:compile).with('*.js', '*.es6', '*.css', '*.html')
    end

    it 'uses js compressor' do
      allow(assets.env).to receive(:js_compressor=).with(anything)
      assets.precompile
      expect(assets.env).to have_received(:js_compressor=).with(assets.uglifier)
      expect(assets.env.js_compressor).to be_nil
    end
  end

  describe '.render' do
    before { described_class.env.append_path 'spec/fixtures' }
    let(:rendered) { assets.render file, site_id: 1 }

    context 'with js' do
      let(:file) { 'test_asset.js' }

      it 'renders js file' do
        expect(rendered)
          .to eql "function modules(data) { $INJECT_MODULES };\n(function test(data) {\n  return modules(data);\n})($INJECT_DATA)\n;\n"
      end
    end

    context 'with sass' do
      let(:file) { 'test_asset.sass' }

      it 'renders sass file' do
        expect(rendered).to eql "#test{color:#fff}\n"
      end

      context 'and syntax error' do
        let(:file) { 'with_syntax_error.sass' }

        it 'raises Sass::SyntaxError' do
          expect { rendered }
            .to raise_error Sass::SyntaxError, 'Invalid CSS after "thisis#wrong": expected selector, was "() {"'
        end
      end
    end

    context 'when file is not found' do
      let(:file) { 'must_be_not_found.js' }

      it 'raises Sprockets::FileNotFound' do
        expect { rendered }
          .to raise_error Sprockets::FileNotFound, "couldn't find file 'must_be_not_found.js' for site #1"
      end
    end
  end

  describe '.render_compressed' do
    before { described_class.env.append_path 'spec/fixtures' }
    let(:rendered) { assets.render_compressed file, site_id: 1 }

    context 'with js' do
      let(:file) { 'test_asset.js' }

      it 'renders and compresses file' do
        expect(rendered).to eql 'function modules(){$INJECT_MODULES}!function(n){modules(n)}($INJECT_DATA);'
      end

      context 'and syntax error' do
        let(:file) { 'with_syntax_error.js' }

        it 'raises ExecJS::ProgramError' do
          expect { rendered }
            .to raise_error ExecJS::Error, 'SyntaxError: Unexpected character \'#\''
        end
      end
    end

    context 'with sass' do
      let(:file) { 'test_asset.sass' }

      it 'renders sass file' do
        expect(rendered).to eql "#test{color:#fff}\n"
      end
    end

    context 'when file is not found' do
      let(:file) { 'must_be_not_found.js' }

      it 'raises Sprockets::FileNotFound' do
        expect { rendered }
          .to raise_error Sprockets::FileNotFound, "couldn't find file 'must_be_not_found.js' for site #1"
      end
    end
  end

  describe '.render_model' do
    let(:site) { create :site }
    let(:model) { StaticScriptModel.new(site) }

    it 'renders models partial to json' do
      expect(assets.jbuilder).to receive(:render).with('static_script_models/static_script_model', model: model)
      assets.render_model(model)
    end
  end

  describe '.digest_path' do
    before do
      allow(StaticScriptAssets)
        .to receive_message_chain(:manifest, :assets)
        .and_return('modules.js' => 'modules-compiled.js')

      allow(StaticScriptAssets)
        .to receive(:digest_path)
        .and_call_original
    end

    it 'returns path to file with a hash' do
      expect(assets.digest_path('modules.js')).to eql 'modules-compiled.js'
    end
  end
end
