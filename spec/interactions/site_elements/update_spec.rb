require 'spec_helper'

describe SiteElements::Update do
  let!(:element) { create(:site_element, :email) }
  let(:valid_params) do
    {
      closable: true,
      show_border: true,
      headline: 'We are Polymathic!'
    }
  end
  let(:interaction) { SiteElements::Update.new(element: element, params: params) }

  subject { interaction.tap(&:run) }

  before do
    allow_any_instance_of(Site).to receive(:regenerate_script)
  end

  def new_element
    subject.element
  end

  context 'when update is successful' do
    let(:params) { valid_params }

    it 'returns true' do
      result = subject
      expect(result).to be_true
    end

    it 'regenerates the script' do
      subject

      expect(element.site).to have_received(:regenerate_script)
    end

    it 'updates the attributes' do
      subject

      expect(new_element.closable).to be_true
      expect(new_element.show_border).to be_true
      expect(new_element.headline).to eq('We are Polymathic!')
    end

    context 'when type is not changed' do
      it 'sets element to the same object' do
        subject

        expect(new_element.id).to eq(element.id)
      end
    end

    context 'when type is changed' do
      let(:params) { valid_params.merge(element_subtype: 'traffic') }

      it 'creates a new element' do
        expect { subject }.to change { SiteElement.count }.by(1)
      end

      it 'sets element to the new element' do
        expect { subject }.to change { SiteElement.count }.by(1)

        expect(new_element.id).not_to eq(element.id)
      end

      it 'disables the original element' do
        subject

        expect(element.reload.paused).to be_true
      end
    end
  end

  context 'when update is unsuccessful' do
    let(:params) { { background_color: '' } }

    it 'returns false' do
      expect(interaction.run).to be_false
    end

    xit "doesn't regenerate the script" do
      subject

      expect(element.site).not_to have_received(:generate_script)
    end

    context 'when type is changed' do
      let(:params) { { background_color: '', element_subtype: 'traffic' } }

      it "doesn't create a new element" do
        expect { subject }.not_to change { SiteElement.count }
      end

      it "doesn't disable original element" do
        subject

        expect(element.reload.paused).to be_false
      end

      context 'when update succeeds but disabling fails' do
        let(:params) { valid_params.update(element_subtype: 'traffic') }

        it "doesn't create new element" do
          allow(element).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError)
          subject

          expect(element.reload.paused).to be_false
        end
      end
    end
  end
end
