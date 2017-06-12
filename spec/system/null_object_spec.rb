describe NullObject do
  it 'returns nil for any method call' do
    null = NullObject.new

    expect(null.missing_method).to be_nil
    expect(null.something_other_missing_method(1, 2, 3)).to be_nil
  end

  it 'responds to missing methods' do
    null = NullObject.new

    expect(null.respond_to?(:missing_method)).to be true
  end
end
