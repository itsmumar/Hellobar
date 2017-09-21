describe UpdateSiteElement do
  let!(:element) { create :bar, :email }
  let(:headline) { 'Updated headline' }
  let(:params) do
    {
      closable: true,
      show_border: true,
      headline: headline
    }
  end
  let(:service) { UpdateSiteElement.new(element, params) }

  before do
    allow_any_instance_of(Site).to receive(:regenerate_script)
  end

  context 'when update is successful' do
    it 'returns element' do
      expect(service.call).to eql element
    end

    it 'regenerates the script' do
      service.call
      expect(element.site).to have_received(:regenerate_script)
    end

    it 'updates the attributes' do
      service.call

      expect(element.closable).to be_truthy
      expect(element.show_border).to be_truthy
      expect(element.headline).to eq headline
    end

    context 'when type is not changed' do
      it 'sets element to the same object' do
        service.call

        expect(element.id).to eq(element.id)
      end
    end

    context 'when type is changed' do
      let(:params) { Hash[element_subtype: 'traffic'] }

      it 'creates a new element' do
        expect { service.call }.to change { SiteElement.count }.by(1)
      end

      it 'sets element to the new element' do
        expect do
          new_element = service.call
          expect(new_element.id).not_to eq(element.id)
        end.to change { SiteElement.count }.by(1)
      end

      it 'pauses the original element' do
        service.call

        expect(element.reload).to be_paused
      end
    end
  end

  context 'when update is unsuccessful' do
    let(:params) { { background_color: '' } }

    it 'raises ActiveRecord::RecordInvalid' do
      expect { service.call }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'does not regenerate the script' do
      expect_any_instance_of(StaticScript).not_to receive(:generate)
      expect { service.call }.to raise_error ActiveRecord::RecordInvalid
    end

    context 'when type is changed' do
      let(:params) { { background_color: '', element_subtype: 'traffic' } }

      it 'does not create a new element' do
        expect { service.call }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and change { SiteElement.count }.by(0)
      end

      it 'does not pause the original element' do
        expect { service.call }.to raise_error ActiveRecord::RecordInvalid
        expect(SiteElement.find(element.id).paused).to be_falsey
      end

      context 'when update succeeds but pausing fails' do
        let(:params) { Hash[element_subtype: 'traffic'] }

        it 'does not create new element' do
          allow(element).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(element))

          expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
          expect(element.reload.paused).to be_falsey
        end
      end
    end
  end

  context 'when use_question has been previously set to true' do
    context 'and theme is a template' do
      let!(:element) { create(:site_element, :email, use_question: true) }
      let(:params) { { use_question: true, theme_id: 'traffic-growth' } }

      it 'returns true' do
        expect(service.call).to be_truthy
      end

      it 'sets use_question to false' do
        expect { service.call }.to change(element, :use_question).from(true).to(false)
      end
    end

    context 'and theme is not a template' do
      let!(:element) { create(:site_element, :email, use_question: true) }
      let(:params) { { use_question: true, theme_id: 'autodetect' } }

      it 'returns true' do
        expect(service.call).to be_truthy
      end

      it 'does not touch use_question' do
        expect { service.call }.not_to change(element, :use_question)
      end
    end
  end

  context 'when active image has been changed' do
    let!(:old_image) { create(:image_upload) }
    let!(:image) { create(:image_upload) }
    let!(:element) { create(:site_element, :email, active_image: old_image) }
    let(:params) { { active_image_id: image.id } }

    it 'destroys previous active image' do
      expect { service.call }
        .to change { ImageUpload.exists? old_image.id }
        .from(true).to(false)
    end
  end
end
