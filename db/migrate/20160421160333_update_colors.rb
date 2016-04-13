class UpdateColors < ActiveRecord::Migration
  def up
    SiteElement.where(type: [Slider, Modal, Takeover]).update_all(
      "button_color = background_color"
    )

    SiteElement.where(type: [Slider, Modal, Takeover]).update_all(
      text_color:         "5c5e60",
      link_color:         "ffffff",
      background_color:   "ffffff"
    )
  end

  def down
    SiteElement.where(type: [Slider, Modal, Takeover]).update_all(
      "background_color = button_color"
    )
  end
end
