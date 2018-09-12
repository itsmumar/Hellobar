class ChangeEnterpriseToElite < ActiveRecord::Migration
  def up
    puts "Found #{ scope.count } subscriptions to change to Elite"
    scope.each do |sub|
      sub.update(type:"Subscription::Elite")
    end
  end

  def scope
    Subscription.where(type:"Subscription::Enterprise")
  end
end
