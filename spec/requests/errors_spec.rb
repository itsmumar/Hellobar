describe 'Error requests' do
  context 'NotFound errors' do
    %w(html js json txt).each do |format|
      describe "GET *.#{ format } (handled format)" do
        it 'does not raise and returns 404 error code' do
          expect {
            get "/nonexisting.#{ format }"
          }.not_to raise_exception

          expect(response.code).to eq '404'
        end
      end
    end

    %w(php png css).each do |format|
      describe "GET *.#{ format } (unhandled format)" do
        it 'does not raise and returns 404 error code' do
          expect {
            get "/nonexisting.#{ format }"
          }.not_to raise_exception

          expect(response.code).to eq '404'
        end
      end
    end
  end
end
