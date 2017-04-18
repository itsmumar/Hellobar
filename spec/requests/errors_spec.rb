describe 'Error requests' do
  context 'Not Found errors' do
    %i(html js css json text).each do |format|
      describe "GET #{ format }" do
        it 'does not raise and returns 404 error' do
          expect {
            get "/nonexisting-page.#{ format }"
          }.not_to raise_exception

          expect(response.code).to eq '404'
        end
      end
    end
  end
end
