module ServiceProviders
  class VerticalResponse < EmbedCodeProvider
    def first_name_param
      'first_name'
    end

    def last_name_param
      'last_name'
    end

    def name_param
      first_name_param
    end
  end
end
