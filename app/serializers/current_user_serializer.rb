class CurrentUserSerializer < UserSerializer
  attributes :email

  has_many :sites
end
