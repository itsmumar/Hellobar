describe RenderStaticScript do
  let(:site) { create(:site, :with_user, :pro_managed, elements: %i[traffic email facebook twitter]) }
  let(:options) { {} }
  let(:service) { described_class.new(site, options) }

  describe '#initialize' do
    it 'pushes static script model to context' do
      expect_any_instance_of(Mustache::Context).to receive(:push).with(instance_of(StaticScriptModel))
      expect(service.model).to be_a StaticScriptModel
    end
  end

  describe '#call' do
    it 'renders static script' do
      expect(service.call).to be_present
    end

    context 'with custom html/js' do
      let(:custom_html) { '<script>alert(1)</script>' }

      before { create(:site_element, :custom, custom_html: custom_html, site: site) }

      it 'escapes </script>' do
        expect(service.call).to include '<script>alert(1)<\/script>'
      end
    end

    context 'when options[:compress]' do
      let(:options) { { compress: true } }

      it 'returns compressed script' do
        allow(service).to receive(:render).and_return 'script'
        allow(StaticScriptAssets).to receive(:compress).with('script').and_return 'compressed'
        expect(service.call).to eql 'compressed'
      end
    end
  end
end
