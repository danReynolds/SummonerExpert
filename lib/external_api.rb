class ExternalApi
  class << self
    def fetch_response(endpoint)
      append_symbol = endpoint.include?('?') ? '&' : '?'
      uri = URI("#{endpoint}#{append_symbol}api_key=#{@api_key}")
      JSON.parse(Net::HTTP.get(uri))
    end
  end
end
