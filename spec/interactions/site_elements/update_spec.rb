describe SiteElements::Update do
  let!(:element) { create(:site_element, :email) }
  let(:headline) { 'Updated headline' }
  let(:valid_params) do
    {
      closable: true,
      show_border: true,
      headline: headline
    }
  end
  let(:interaction) { SiteElements::Update.new(element: element, params: params) }

  subject(:run_interaction) { interaction.tap(&:run) }

  before do
    allow_any_instance_of(Site).to receive(:regenerate_script)
  end

  def new_element
    run_interaction.element
  end

  context 'when update is successful' do
    let(:params) { valid_params }

    it 'returns true' do
      result = run_interaction
      expect(result).to be_truthy
    end

    it 'regenerates the script' do
      run_interaction

      expect(element.site).to have_received(:regenerate_script)
    end

    it 'updates the attributes' do
      run_interaction

      expect(new_element.closable).to be_truthy
      expect(new_element.show_border).to be_truthy
      expect(new_element.headline).to eq headline
    end

    context 'when type is not changed' do
      it 'sets element to the same object' do
        run_interaction

        expect(new_element.id).to eq(element.id)
      end
    end

    context 'when type is changed' do
      let(:params) { valid_params.merge(element_subtype: 'traffic') }

      it 'creates a new element' do
        expect { run_interaction }.to change { SiteElement.count }.by(1)
      end

      it 'sets element to the new element' do
        expect { run_interaction }.to change { SiteElement.count }.by(1)

        expect(new_element.id).not_to eq(element.id)
      end

      it 'pauses the original element' do
        run_interaction

        expect(element.reload).to be_paused
      end
    end
  end

  context 'when update is unsuccessful' do
    let(:params) { { background_color: '' } }

    it 'returns false' do
      expect(interaction.run).to be_falsey
    end

    it 'does not regenerate the script' do
      expect(element.site.script).not_to receive(:generate)
      run_interaction
    end

    context 'when type is changed' do
      let(:params) { { background_color: '', element_subtype: 'traffic' } }

      it 'does not create a new element' do
        expect { run_interaction }.not_to change { SiteElement.count }
      end

      it 'does not pause the original element' do
        run_interaction

        expect(SiteElement.find(element.id).paused).to be_falsey
      end

      context 'when update succeeds but pausing fails' do
        let(:params) { valid_params.update(element_subtype: 'traffic') }

        it 'does not create new element' do
          allow(element).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError)
          run_interaction

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
        expect(interaction.run).to be_truthy
      end

      it 'sets use_question to false' do
        expect { run_interaction }.to change(element, :use_question).from(true).to(false)
      end
    end

    context 'and theme is not a template' do
      let!(:element) { create(:site_element, :email, use_question: true) }
      let(:params) { { use_question: true, theme_id: 'autodetect' } }

      it 'returns true' do
        expect(interaction.run).to be_truthy
      end

      it 'does not touch use_question' do
        expect { run_interaction }.not_to change(element, :use_question)
      end
    end
  end
end
