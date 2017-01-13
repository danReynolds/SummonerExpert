class ExternalApi
  class << self
    def fetch_response(endpoint)
      append_symbol = endpoint.include?('?') ? '&' : '?'
      uri = URI("#{endpoint}#{append_symbol}api_key=#{@api_key}")
      response = JSON.parse(Net::HTTP.get(uri))
      if response.is_a?(Hash)
        response = response.with_indifferent_access
        response[:data] ? response[:data] : response
      end
    end
  end
end
