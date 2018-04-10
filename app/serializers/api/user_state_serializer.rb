class ApiSerializer
  class UserStateSerializer < ActiveModel::Serializer
    attributes :user, :sites, :site_memberships, :rules, :site_elements, :credit_cards

    def rules
      rules = user.sites.map(&:rules).flatten
      rules.map { |rule| RuleSerializer.new(rule).as_json }
    end

    def user
      object
    end
  end
end
