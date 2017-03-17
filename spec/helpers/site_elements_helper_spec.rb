require 'spec_helper'

describe SiteElementsHelper do
  describe 'site_element_subtypes_for_site' do
    let(:site) { create(:site) }

    context 'none' do
      before do
        site.stub(site_elements: [])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to eq([])
      end
    end

    context 'traffic' do
      before do
        site.stub(site_elements: [create(:site_element, :traffic)])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to eq(['traffic'])
      end
    end

    context 'email' do
      before do
        site.stub(site_elements: [create(:site_element, :email)])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to eq(['email'])
      end
    end

    context 'multiple' do
      before do
        site.stub(site_elements: [create(:site_element, :traffic), create(:site_element, :email)])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to match_array(['traffic', 'email'])
      end
    end
  end

  describe '#helper.activity_message' do
    it "doesn't pluralize when there was only one conversion" do
      element = create(:site_element, :email)
      element.stub(total_conversions: 1, total_views: 1)
      expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 1 email collected/)
    end

    context 'with multiple conversions' do
      it 'returns the correct message for traffic elements' do
        element = create(:site_element, :traffic)
        element.stub(total_conversions: 5, total_views: 5)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 clicks/)
      end

      it 'returns the correct message for email elements' do
        element = create(:site_element, :email)
        element.stub(total_conversions: 5, total_views: 5)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 emails collected/)
      end

      it 'returns the correct message for twitter elements' do
        Hello::DataAPI.stub(lifetime_totals: {})
        element = create(:site_element, :twitter)
        element.stub(total_conversions: 5, total_views: 5)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 tweets/)
      end

      it 'returns the correct message for facebook elements' do
        Hello::DataAPI.stub(lifetime_totals: {})
        element = create(:site_element, :facebook)
        element.stub(total_conversions: 5, total_views: 5)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 likes/)
      end
    end

    it 'shows the conversion rate relative to other elements of the same type' do
      rule = create(:rule)
      element = create(:site_element, :twitter, rule: rule)
      Hello::DataAPI.stub(lifetime_totals: {
        element.id.to_s => Hello::DataAPI::Performance.new([[10, 5]]),
        create(:site_element, :twitter, rule: rule).id.to_s => Hello::DataAPI::Performance.new([[10, 1]])
      })

      expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/converting 400\.0% better than your other social bars/)
    end

    it "doesn't show a percentage when comparing against other bars with no conversions" do
      rule = create(:rule)
      element = create(:site_element, :twitter, rule: rule)
      Hello::DataAPI.stub(lifetime_totals: {
        element.id.to_s => Hello::DataAPI::Performance.new([[10, 5]]),
        create(:site_element, :twitter, rule: rule).id.to_s => Hello::DataAPI::Performance.new([[10, 0]])
      })

      expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/converting better than your other social bars/)
    end

    it 'doesnt return the conversion rate when it is Infinite' do
      element = create(:site_element, :twitter)
      Hello::DataAPI.stub(lifetime_totals: {
        element.id.to_s => Hello::DataAPI::Performance.new([[0, 5]]),
        create(:site_element, :facebook).id.to_s => Hello::DataAPI::Performance.new([[10, 1]])
      })

      expect(helper.activity_message_for_conversion(element, element.related_site_elements)).not_to match(/Currently this bar is converting/)
    end
  end

  describe 'site_element_activity_units' do
    before(:each) do
      @bars = {
        traffic: SiteElement.new(element_subtype: 'traffic'),
        email: SiteElement.new(element_subtype: 'email'),
        announcement: SiteElement.new(element_subtype: 'announcement'),
        tweet_on_twitter: SiteElement.new(element_subtype: 'social/tweet_on_twitter'),
        follow_on_twitter: SiteElement.new(element_subtype: 'social/follow_on_twitter'),
        like_on_facebook: SiteElement.new(element_subtype: 'social/like_on_facebook'),
        share_on_linkedin: SiteElement.new(element_subtype: 'social/share_on_linkedin'),
        plus_one_on_google_plus: SiteElement.new(element_subtype: 'social/plus_one_on_google_plus'),
        pin_on_pinterest: SiteElement.new(element_subtype: 'social/pin_on_pinterest'),
        follow_on_pinterest: SiteElement.new(element_subtype: 'social/follow_on_pinterest'),
        share_on_buffer: SiteElement.new(element_subtype: 'social/share_on_buffer')
      }
    end

    it 'returns the correct units for all bar types' do
      expect(site_element_activity_units(@bars[:traffic])).to eq('click')
      expect(site_element_activity_units(@bars[:email])).to eq('email')
      expect(site_element_activity_units(@bars[:announcement])).to eq('view')
      expect(site_element_activity_units(@bars[:tweet_on_twitter])).to eq('tweet')
      expect(site_element_activity_units(@bars[:follow_on_twitter])).to eq('follower')
      expect(site_element_activity_units(@bars[:like_on_facebook])).to eq('like')
      expect(site_element_activity_units(@bars[:share_on_linkedin])).to eq('share')
      expect(site_element_activity_units(@bars[:plus_one_on_google_plus])).to eq('plus one')
      expect(site_element_activity_units(@bars[:pin_on_pinterest])).to eq('pin')
      expect(site_element_activity_units(@bars[:follow_on_pinterest])).to eq('follower')
      expect(site_element_activity_units(@bars[:share_on_buffer])).to eq('share')
    end

    it 'optionally adds an appropriate verb' do
      expect(site_element_activity_units(@bars[:traffic], verb: true)).to eq('click')
      expect(site_element_activity_units(@bars[:email], verb: true)).to eq('email collected')
      expect(site_element_activity_units(@bars[:announcement], verb: true)).to eq('view')
      expect(site_element_activity_units(@bars[:tweet_on_twitter], verb: true)).to eq('tweet')
      expect(site_element_activity_units(@bars[:follow_on_twitter], verb: true)).to eq('follower gained')
      expect(site_element_activity_units(@bars[:like_on_facebook], verb: true)).to eq('like')
      expect(site_element_activity_units(@bars[:share_on_linkedin], verb: true)).to eq('share')
      expect(site_element_activity_units(@bars[:plus_one_on_google_plus], verb: true)).to eq('plus one')
      expect(site_element_activity_units(@bars[:pin_on_pinterest], verb: true)).to eq('pin')
      expect(site_element_activity_units(@bars[:follow_on_pinterest], verb: true)).to eq('follower gained')
      expect(site_element_activity_units(@bars[:share_on_buffer], verb: true)).to eq('share')
      expect(site_element_activity_units([@bars[:traffic], @bars[:email]], verb: true)).to eq('conversion')
    end

    it 'pluralizes correctly with verb' do
      expect(site_element_activity_units(@bars[:traffic], plural: true, verb: true)).to eq('clicks')
      expect(site_element_activity_units(@bars[:email], plural: true, verb: true)).to eq('emails collected')
      expect(site_element_activity_units(@bars[:announcement], plural: true, verb: true)).to eq('views')
      expect(site_element_activity_units(@bars[:tweet_on_twitter], plural: true, verb: true)).to eq('tweets')
      expect(site_element_activity_units(@bars[:follow_on_twitter], plural: true, verb: true)).to eq('followers gained')
      expect(site_element_activity_units(@bars[:like_on_facebook], plural: true, verb: true)).to eq('likes')
      expect(site_element_activity_units(@bars[:share_on_linkedin], plural: true, verb: true)).to eq('shares')
      expect(site_element_activity_units(@bars[:plus_one_on_google_plus], plural: true, verb: true)).to eq('plus ones')
      expect(site_element_activity_units(@bars[:pin_on_pinterest], plural: true, verb: true)).to eq('pins')
      expect(site_element_activity_units(@bars[:follow_on_pinterest], plural: true, verb: true)).to eq('followers gained')
      expect(site_element_activity_units(@bars[:share_on_buffer], plural: true, verb: true)).to eq('shares')
      expect(site_element_activity_units([@bars[:traffic], @bars[:email]], plural: true, verb: true)).to eq('conversions')
    end

    it 'optionally pluralizes the units' do
      expect(site_element_activity_units(@bars[:traffic], plural: true)).to eq('clicks')
      expect(site_element_activity_units(@bars[:email], plural: true)).to eq('emails')
      expect(site_element_activity_units(@bars[:announcement], plural: true)).to eq('views')
      expect(site_element_activity_units(@bars[:tweet_on_twitter], plural: true)).to eq('tweets')
      expect(site_element_activity_units(@bars[:follow_on_twitter], plural: true)).to eq('followers')
      expect(site_element_activity_units(@bars[:like_on_facebook], plural: true)).to eq('likes')
      expect(site_element_activity_units(@bars[:share_on_linkedin], plural: true)).to eq('shares')
      expect(site_element_activity_units(@bars[:plus_one_on_google_plus], plural: true)).to eq('plus ones')
      expect(site_element_activity_units(@bars[:pin_on_pinterest], plural: true)).to eq('pins')
      expect(site_element_activity_units(@bars[:follow_on_pinterest], plural: true)).to eq('followers')
      expect(site_element_activity_units(@bars[:share_on_buffer], plural: true)).to eq('shares')
    end

    it 'consolidates multiple bar types into a unit that makes sense for all' do
      other_traffic_bar = SiteElement.new(element_subtype: 'traffic')
      expect(site_element_activity_units([other_traffic_bar, @bars[:traffic]])).to eq('click')
      expect(site_element_activity_units([other_traffic_bar, @bars[:traffic], @bars[:email]])).to eq('conversion')
    end
  end

  describe 'ab_test_icon' do
    it 'returns the A/B icon for paused bars' do
      se = create(:site_element, :traffic)
      se.update_attribute(:paused, true)

      expect(helper.ab_test_icon(se)).to include('icon-abtest')
    end

    it 'returns the bars indexed by letter' do
      se1 = create(:site_element, :bar, :traffic)
      se2 = se1.dup
      se2.created_at = se1.created_at + 1.minute
      se2.save

      allow_any_instance_of(SiteElement).to receive(:total_conversions).and_return(250)
      allow_any_instance_of(SiteElement).to receive(:total_views).and_return(500)

      expect(helper.ab_test_icon(se1)).to include("<span class='numbers'>A</span>")
      expect(helper.ab_test_icon(se2)).to include("<span class='numbers'>B</span>")
    end

    it "uses icon-tip for the 'winning' bar" do
      se1 = create(:site_element, :traffic)
      se2 = se1.dup
      se2.save

      allow(se1).to receive(:total_conversions) { 250 }
      allow(se1).to receive(:total_views)       { 500 }
      allow(se2).to receive(:total_conversions) { 100 }
      allow(se2).to receive(:total_views)       { 500 }

      allow_any_instance_of(Rule).to receive(:site_elements).and_return([se1, se2])

      expect(helper.ab_test_icon(se1)).to include('icon-tip')
      expect(helper.ab_test_icon(se2)).to include('icon-circle')
    end

    it 'does not group elements that are in different rules' do
      variation1 = create(:site_element, :bar, :traffic)
      variation2 = variation1.dup
      variation3 = variation1.dup

      variation2.save
      other_rule = create(:rule, site: variation1.site)
      variation3.rule = other_rule
      variation3.save

      allow(variation3).to receive(:rule_id) { 0 }

      allow(variation1).to receive(:total_views) { 250 }
      allow(variation2).to receive(:total_views) { 250 }
      allow(variation3).to receive(:total_views) { 250 }

      allow(variation1).to receive(:total_conversions) { 250 }
      allow(variation2).to receive(:total_conversions) { 250 }
      allow(variation3).to receive(:total_conversions) { 250 }

      allow_any_instance_of(Site).to receive(:site_elements).and_return([variation1, variation2, variation3])

      icon = helper.ab_test_icon(variation1)
      icon2 = helper.ab_test_icon(variation2)
      icon3 = helper.ab_test_icon(variation3)

      expect(icon).to include('icon-circle')
      expect(icon2).to include('icon-circle')
      expect(icon3).to include('icon-abtest')
    end

    it 'only groups elements with the same type' do
      site = create(:site, :with_rule)
      variation1 = create(:site_element, :bar, :traffic, site: site)
      variation2 = create(:site_element, :bar, :traffic, site: site)
      variation3 = create(:site_element, :slider, :traffic, site: site)

      icon1 = helper.ab_test_icon(variation1)
      icon2 = helper.ab_test_icon(variation2)
      icon3 = helper.ab_test_icon(variation3)

      expect(icon1).to include('icon-circle')
      expect(icon2).to include('icon-circle')
      expect(icon3).to include('icon-abtest')
    end
  end

  describe 'elements_grouped_by_type' do
    let(:site) { create(:site, elements: %i(traffic email twitter facebook)) }

    it 'should group elements by type' do
      grouped_elements = helper.elements_grouped_by_type(site.site_elements)

      expect(grouped_elements.count).to eq 2
      expect(grouped_elements[0].count).to eq 4
      expect(grouped_elements[1].count).to eq 0
    end
  end

  describe 'elements_grouped_by_subtype' do
    let(:site) { create(:site, elements: %i(traffic email twitter facebook)) }

    it 'should group elements by subtype' do
      create(:site_element, :call, site: site)
      grouped_elements = helper.elements_grouped_by_subtype(site.site_elements)

      expect(grouped_elements.count).to eq 4
      expect(grouped_elements[0].count).to eq 1
      expect(grouped_elements[1].count).to eq 2
      expect(grouped_elements[2].count).to eq 1
      expect(grouped_elements[3].count).to eq 1
    end
  end
end
