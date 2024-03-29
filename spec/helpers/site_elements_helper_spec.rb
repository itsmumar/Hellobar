describe SiteElementsHelper do
  before do
    @user = create(:user)
    allow(helper).to receive(:current_user).and_return(@user)
  end

  describe 'site_element_subtypes_for_site' do
    let(:site) { create(:site) }

    context 'none' do
      before do
        allow(site).to receive(:site_elements).and_return([])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to eq([])
      end
    end

    context 'traffic' do
      before do
        allow(site).to receive(:site_elements).and_return([create(:site_element, :traffic)])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to eq(['traffic'])
      end
    end

    context 'email' do
      before do
        allow(site).to receive(:site_elements).and_return([create(:site_element, :email)])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to eq(['email'])
      end
    end

    context 'multiple' do
      before do
        allow(site)
          .to receive(:site_elements).and_return([create(:site_element, :traffic), create(:site_element, :email)])
      end

      it 'returns valid types' do
        expect(helper.site_element_subtypes_for_site(site)).to match_array(['traffic', 'email'])
      end
    end
  end

  describe '#helper.activity_message' do
    it "doesn't pluralize when there was only one conversion" do
      element = create(:site_element, :email)
      allow(element).to receive(:total_conversions).and_return(1)
      allow(element).to receive(:total_views).and_return(1)

      expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 1 email collected/)
    end

    context 'with multiple conversions' do
      def stub_views_and_conversations(element)
        allow(element).to receive(:total_conversions).and_return(5)
        allow(element).to receive(:total_views).and_return(5)
      end

      it 'returns the correct message for traffic elements' do
        element = create(:site_element, :traffic)
        stub_views_and_conversations(element)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 clicks/)
      end

      it 'returns the correct message for email elements' do
        element = create(:site_element, :email)
        stub_views_and_conversations(element)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 emails collected/)
      end

      it 'returns the correct message for twitter elements' do
        element = create(:site_element, :twitter)
        stub_views_and_conversations(element)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 tweets/)
      end

      it 'returns the correct message for facebook elements' do
        element = create(:site_element, :facebook)
        stub_views_and_conversations(element)
        expect(helper.activity_message_for_conversion(element, element.related_site_elements)).to match(/resulted in 5 likes/)
      end
    end

    describe 'conversion rate relative to other elements of the same type' do
      let(:rule) { create(:rule) }
      let(:element) { create(:site_element, :twitter, rule: rule) }
      let(:other_element) { create(:site_element, :twitter, rule: rule) }

      let(:total_views) { 10 }

      let(:element_stats) do
        [
          create(:site_statistics_record, views: 10, conversions: element_conversions, site_element_id: element.id),
          create(:site_statistics_record, views: 10, conversions: other_conversions, site_element_id: other_element.id)
        ]
      end

      subject(:message) { helper.activity_message_for_conversion(element, element.related_site_elements) }

      before do
        expect(FetchSiteStatistics)
          .to receive_service_call
          .exactly(2)
          .times
          .with(rule.site)
          .and_return(SiteStatistics.new(element_stats))
      end

      context 'when element performs better than other' do
        let(:element_conversions) { 5 }
        let(:other_conversions) { 1 }

        it 'states that element is converting better' do
          expect(message).to match(%r{converting 400.0% better than your other social bars})
        end
      end

      context 'when element performs worse than other' do
        let(:element_conversions) { 1 }
        let(:other_conversions) { 5 }

        it 'states that element is converting worse' do
          expect(message).to match(%r{converting 80.0% worse than your other social bars})
        end
      end

      context 'when element performs the same as other' do
        let(:element_conversions) { 3 }
        let(:other_conversions) { 3 }

        it 'states that element is converting exactly the same as others' do
          expect(message).to match(/converting exactly as well as your other social bars/)
        end
      end
    end

    it "doesn't show a percentage when comparing against other bars with no conversions" do
      rule = create(:rule)
      element = create(:site_element, :twitter, rule: rule)
      other_element = create(:site_element, :twitter, rule: rule)

      records = [
        create(:site_statistics_record, views: 10, conversions: 5, site_element_id: element.id),
        create(:site_statistics_record, views: 10, conversions: 0, site_element_id: other_element.id)
      ]
      expect(FetchSiteStatistics)
        .to receive_service_call
        .exactly(2)
        .times
        .with(rule.site)
        .and_return(SiteStatistics.new(records))

      expect(helper.activity_message_for_conversion(element, element.related_site_elements))
        .to match(/converting better than your other social bars/)
    end

    it 'doesnt return the conversion rate when it is Infinite' do
      element = create(:site_element, :twitter)
      other_element = create(:site_element, :facebook)
      records = [
        create(:site_statistics_record, site_element_id: element.id),
        create(:site_statistics_record, views: 10, conversions: 1, site_element_id: other_element.id)
      ]
      statistics = SiteStatistics.new(records)
      expect(FetchSiteStatistics).to receive_service_call.and_return(statistics)

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
    before do
      allow_any_instance_of(FetchSiteStatistics)
        .to receive(:call).and_return(SiteStatistics.new)
    end

    it 'returns the A/B icon for paused bars' do
      se = create(:site_element, :traffic)
      se.pause!

      expect(helper.ab_test_icon(se)).to include('icon-abtest')
    end

    it 'returns the bars indexed by letter' do
      se1 = create(:site_element, :traffic)
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
      variation1 = create(:site_element, :traffic)
      variation2 = variation1.dup
      variation3 = variation1.dup

      variation2.save
      other_rule = create(:rule, site: variation1.site)
      variation3.rule = other_rule
      variation3.save

      allow(variation3).to receive(:rule_id) { 0 }

      statistics = create(:site_statistics, views: [250], conversions: [250])
      allow_any_instance_of(FetchSiteStatistics)
        .to receive(:call).and_return(statistics)

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
      variation1 = create(:site_element, :traffic, site: site)
      variation2 = create(:site_element, :traffic, site: site)
      variation3 = create(:slider, :traffic, site: site)

      icon1 = helper.ab_test_icon(variation1)
      icon2 = helper.ab_test_icon(variation2)
      icon3 = helper.ab_test_icon(variation3)

      expect(icon1).to include('icon-circle')
      expect(icon2).to include('icon-circle')
      expect(icon3).to include('icon-abtest')
    end
  end

  describe 'elements_grouped_by_type' do
    let(:site) { create(:site, elements: %i[traffic email twitter facebook]) }

    it 'should group elements by type' do
      grouped_elements = helper.elements_grouped_by_type(site.site_elements)

      expect(grouped_elements.count).to eq 2
      expect(grouped_elements[0].count).to eq 4
      expect(grouped_elements[1].count).to eq 0
    end
  end

  describe 'elements_grouped_by_subtype' do
    let(:site) { create(:site, elements: %i[traffic email twitter facebook]) }

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

  describe '#render_headline' do
    let(:site) { create(:site, elements: %i[traffic email twitter facebook]) }
    let(:slider_element) { create(:site_element, site: site, headline: '<b>Headline</b>') }

    it 'strips tags' do
      expect(helper.render_headline(slider_element)).to eql 'Headline'
    end

    context 'when use_question' do
      let(:slider_element) { create(:site_element, site: site, use_question: true, question: '<b>Questions?</b>') }

      it 'strips tags' do
        expect(helper.render_headline(slider_element)).to eql 'Questions?'
      end
    end
  end
end
