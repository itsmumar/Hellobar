require 'spec_helper'
require 'color'

describe Color do
  describe '.color_is_bright?' do
    it 'returns true for white' do
      expect(Color.color_is_bright?('FFFFFF')).to be(true)
    end

    it 'returns false for black' do
      expect(Color.color_is_bright?('000000')).to be(false)
    end

    it 'returns true for some other bright color' do
      expect(Color.color_is_bright?('97eda6')).to be(true)
    end
  end

  describe '.hex_string_to_rgb' do
    it 'turns a hex string to an array of rgb ints' do
      expect(Color.hex_string_to_rgb('FF00FF')).to eq([255, 0, 255])
    end

    it 'can have a hash at the beginning' do
      expect(Color.hex_string_to_rgb('#FF00FF')).to eq([255, 0, 255])
    end
  end

  describe '.luminance' do
    it 'calculates the luminance of rgb values' do
      expect(Color.luminance(255, 0, 255)).to eq(0.2848)
    end

    it 'returns 1.0 for #FFF' do
      expect(Color.luminance(255, 255, 255)).to be_within(0.001).of(1)
    end

    it 'returns 0 for #000' do
      expect(Color.luminance(0, 0, 0)).to be_within(0.001).of(0)
    end
  end
end
