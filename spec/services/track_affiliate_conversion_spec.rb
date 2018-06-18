describe TrackAffiliateConversion do
  let(:user) { create :user, :affiliate }
  let(:gateway) { instance_double TapfiliateGateway }
  let(:track_conversion) { TrackAffiliateConversion.new(user) }
  let(:successful_response) { double 'Successful response', success?: true }
  let(:erroneous_response) { double 'Erroneous response', success?: false }
  let(:conversion_identifier) { '5' }
  let(:error) { 'Error' }

  describe '#call' do
    before do
      allow(TapfiliateGateway).to receive(:new).and_return gateway
    end

    context 'when TapfiliateGateway responds with success' do
      before do
        allow(successful_response).to receive(:[]).with('id').and_return conversion_identifier

        expect(gateway).to receive(:store_conversion)
          .with(user: user).and_return successful_response
      end

      it 'sends `store_conversion` request to TapfiliateGateway' do
        track_conversion.call
      end

      it 'saves conversion_identifier' do
        track_conversion.call

        expect(user.affiliate_information.conversion_identifier).to eql conversion_identifier
      end
    end

    context 'when Tapfialite responds with an error' do
      before do
        allow(erroneous_response).to receive(:[]).with('errors').and_return error

        expect(gateway).to receive(:store_conversion)
          .with(user: user).and_return erroneous_response
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:info).with a_string_matching error

        track_conversion.call
      end
    end
  end
end
