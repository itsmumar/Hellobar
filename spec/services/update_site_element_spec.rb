require 'spec_helper'

describe UpdateSiteElement do
  fixtures :site_elements, :sites, :rules

  let(:element) { site_elements(:zombo_email) }

  describe "#update" do
    let(:valid_params) do
      {
        closable: true,
        show_border: true,
        headline: "We are Polymathic!"
      }
    end

    before do
      allow_any_instance_of(Site).to receive(:generate_script)
    end

    context "when update is successful" do
      it "returns true" do
          updater = UpdateSiteElement.new(element)

          result = updater.update(valid_params)

          expect(result).to be_true
      end

      it "regenerates the script" do
        updater = UpdateSiteElement.new(element)

        updater.update(valid_params)

        expect(element.site).to have_received(:generate_script)
      end

      it "updates the attributes" do
        updater = UpdateSiteElement.new(element)

        updater.update(valid_params)

        expect(updater.element.closable).to be_true
        expect(updater.element.show_border).to be_true
        expect(updater.element.headline).to eq("We are Polymathic!")
      end


      context "when type is not changed" do
        it "sets element to the same object" do
          updater = UpdateSiteElement.new(element)

          updater.update(valid_params)

          expect(updater.element.id).to eq(element.id)
        end
      end

      context "when type is changed" do
        before do
          valid_params[:element_subtype] = "traffic"
        end

        it "creates a new element" do
          updater = UpdateSiteElement.new(element)

          expect {
            updater.update(valid_params)
          }.to change { SiteElement.count }.by(1)
        end

        it "sets element to the new element" do
          updater = UpdateSiteElement.new(element)

          updater.update(valid_params)

          expect(updater.element.id).to_not eq(updater.orig_element.id)
        end

        it "clones the original element & sets new type" do
          updater = UpdateSiteElement.new(element)
          allow(updater).to receive(:dup_element_with_type).and_call_original

          updater.update(valid_params)

          expect(updater).to have_received(:dup_element_with_type)
        end

        it "disables the original element" do
          updater = UpdateSiteElement.new(element)

          updater.update(valid_params)

          expect(element.reload.paused).to be_true
        end
      end
    end

    context "when update is unsuccessful" do
      let(:invalid_params) { { background_color: "" } }

      it "returns false" do
        updater = UpdateSiteElement.new(element)

        result = updater.update(invalid_params)

        expect(result).to be_false
      end

      xit "doesn't regenerate the script" do
        updater = UpdateSiteElement.new(element)

        updater.update(valid_params)

        expect(element.site).not_to have_received(:generate_script)
      end

      context "when type is changed" do
        before do
          invalid_params[:element_subtype] = "traffic"
        end

        it "doesn't create a new element" do
          updater = UpdateSiteElement.new(element)

          expect {
            updater.update(invalid_params)
          }.not_to change { SiteElement.count }
        end

        it "doesn't disable original element" do
          updater = UpdateSiteElement.new(element)

          updater.update(invalid_params)

          expect(element.reload.paused).to be_false
        end


        context "when update succeeds but disabling fails" do
          it "doesn't create new element" do
            valid_params[:element_subtype] = "traffic"
            allow(element).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError)
            updater = UpdateSiteElement.new(element)

            updater.update(valid_params)

            expect(element.reload.paused).to be_false
          end
        end
      end
    end
  end

  describe "#dup_element_with_type" do
    it "creates a new element with new type" do
      updater = UpdateSiteElement.new(element)

      new_element = updater.dup_element_with_type("traffic")

      expect(new_element.element_subtype).to eq("traffic")
    end

    it "doesn't save the new element" do
      updater = UpdateSiteElement.new(element)

      new_element = updater.dup_element_with_type("traffic")

      expect(new_element).to be_new_record
    end

    it "changes the type of the new element" do
      updater = UpdateSiteElement.new(element)

      new_element = updater.dup_element_with_type("traffic")

      expect(new_element.element_subtype).to eq("traffic")
    end

    it "clones the element" do
      updater = UpdateSiteElement.new(element)
      element_attrs = element.cloneable_attributes

      new_element = updater.dup_element_with_type("traffic")

      element_attrs.keys.each do |attr|
        orig_val = element.send(attr)
        new_val = new_element.send(attr)

        expect(new_val).to(
          eq(orig_val),
          "expected #{attr} to equal #{orig_val} but was #{new_val}"
        )
      end
    end

    it "keeps the original paused value" do
      updater = UpdateSiteElement.new(element)
      element.update_attributes(paused: false)

      new_element = updater.dup_element_with_type("traffic")

      expect(new_element.paused).to be_false
    end
  end
end
