module Faraday
  class NotFound < Faraday::ClientError
  end

  class Unauthorized < Faraday::ClientError
  end

  class Conflict < Faraday::ClientError
  end

  class BadRequest < Faraday::ClientError
  end
end
