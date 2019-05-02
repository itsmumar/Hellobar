class UpdateConversionCtaTexr < ActiveRecord::Migration
  def change
    SiteElement.update_all conversion_cta_text: 'Close'
  end
end
