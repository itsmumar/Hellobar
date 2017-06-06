describe CleanEmbedCode do
  let(:service) { CleanEmbedCode.new(embed_code) }

  context 'curly quotes' do
    let(:embed_code) do
      '<html><body><iframe><form>“I want to go to Việt Nam”, he said.</form></iframe></body></html>'
    end

    describe '#call' do
      it 'replaces quotes to standart ones' do
        expect(service.call).not_to match(/“|”/)
      end

      it 'deletes non-ascii chars' do
        expect(service.call).not_to include 'ệ'
      end
    end
  end
end
