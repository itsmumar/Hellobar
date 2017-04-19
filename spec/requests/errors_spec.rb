describe 'Error requests' do
  context 'NotFound errors' do
    %w(html js css json txt).each do |format|
      describe "GET *.#{ format }" do
        it 'does not raise and returns 404 error code' do
          expect {
            get "/nonexisting-page.#{ format }"
          }.not_to raise_exception

          expect(response.code).to eq '404'
        end
      end
    end
  end

  context 'UnknownFormat errors' do
    describe 'GET *.php' do
      it 'does not raise and returns 422 error code' do
        expect {
          get '/wp-login.php'
        }.not_to raise_exception

        expect(response.code).to eq '422'
      end
    end
  end
end
