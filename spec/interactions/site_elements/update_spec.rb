require 'spec_helper'

describe SiteElements::Update do
  fixtures :site_elements, :sites, :rules

  before :each do
    @element = site_elements(:zombo_email)
    @valid_params = {
      closable: true,
      show_border: true,
      headline: 'We are Polymathic!'
    }
    allow_any_instance_of(Site).to receive(:regenerate_script)
  end

  def update(params:)
    @interaction = SiteElements::Update.new(
      element: @element,
      params: params
    )
    @interaction.run
  end

  def new_element
    @interaction.element
  end

  context 'when update is successful' do
    it 'returns true' do
      result = update(params: @valid_params)

      expect(result).to be_true
    end

    it 'regenerates the script' do
      update(params: @valid_params)

      expect(@element.site).to have_received(:regenerate_script)
    end

    it 'updates the attributes' do
      update(params: @valid_params)

      expect(new_element.closable).to be_true
      expect(new_element.show_border).to be_true
      expect(new_element.headline).to eq('We are Polymathic!')
    end

    context 'when type is not changed' do
      it 'sets element to the same object' do
        update(params: @valid_params)

        expect(new_element.id).to eq(@element.id)
      end
    end

    context 'when type is changed' do
      before do
        @new_type_params = @valid_params.merge(element_subtype: 'traffic')
      end

      it 'creates a new element' do
        expect { update(params: @new_type_params) }.to change { SiteElement.count }.by(1)
      end

      it 'sets element to the new element' do
        expect { update(params: @new_type_params) }.to change { SiteElement.count }.by(1)

        expect(new_element.id).not_to eq(@element.id)
      end

      it 'disables the original element' do
        update(params: @new_type_params)

        expect(@element.reload.paused).to be_true
      end
    end
  end

  context 'when update is unsuccessful' do
    before :each do
      @invalid_params = { background_color: '' }
    end

    it 'returns false' do
      result = update(params: @invalid_params)

      expect(result).to be_false
    end

    xit "doesn't regenerate the script" do
      update(params: @invalid_params)

      expect(@element.site).not_to have_received(:generate_script)
    end

    context 'when type is changed' do
      before do
        @invalid_params.merge!(element_subtype: 'traffic')
      end

      it "doesn't create a new element" do
        expect { update(params: @invalid_params) }.not_to change { SiteElement.count }
      end

      it "doesn't disable original element" do
        update(params: @invalid_params)

        expect(@element.reload.paused).to be_false
      end

      context 'when update succeeds but disabling fails' do
        it "doesn't create new element" do
          @valid_params[:element_subtype] = 'traffic'
          allow(@element).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError)
          update(params: @valid_params)

          expect(@element.reload.paused).to be_false
        end
      end
    end
  end
end
