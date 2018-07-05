class MigrateInfusionsoft < ActiveRecord::Migration
  def up
    Identity.where(provider: 'infusionsoft').update_all provider: 'infusion_soft'
  end

  def down
    Identity.where(provider: 'infusion_soft').update_all provider: 'infusionsoft'
  end
end
