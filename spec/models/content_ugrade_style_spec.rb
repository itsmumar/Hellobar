describe ContentUpgradeStyles do
  it { is_expected.to validate_inclusion_of(:offer_font_family_name).in_array(ContentUpgradeStyles::AVAILABLE_FONTS.keys) }
end
