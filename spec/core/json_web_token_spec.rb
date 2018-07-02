describe JsonWebToken do
  it 'allows encoding and decoding custom payload in JWT tokens' do
    payload = Hash['user_id' => 5]

    encoded_message = JsonWebToken.encode payload

    expect(encoded_message.length).to be > 50
    expect(encoded_message).to match(/.+\..+\..+/) # 3 dot separated parts

    decoded_message = JsonWebToken.decode encoded_message

    expect(decoded_message).to eq payload
  end

  it 'raises on decoding incorrect payload' do
    expect { JsonWebToken.decode 'xxx' }
      .to raise_exception JWT::DecodeError
  end

  it 'raises on decoding with incorrect signature' do
    decoded_message = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1fQ.xxx'

    expect { JsonWebToken.decode decoded_message }
      .to raise_exception JWT::VerificationError
  end
end
