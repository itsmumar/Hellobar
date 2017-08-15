class ApiSerializer
  class UserStateSerializer < ActiveModel::Serializer
    attributes :user, :sites, :site_memberships, :rules, :site_elements, :credit_cards

    def rules
      rules = sites.map(&:rules).flatten

      ActiveModel::ArraySerializer.new(rules)
    end

    def user
      object
    end
  end
end
