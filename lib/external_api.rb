class ExternalApi
  class << self
    attr_accessor :api
    
    def fetch_response(endpoint)
      append_symbol = endpoint.include?('?') ? '&' : '?'
      uri = URI("#{endpoint}#{append_symbol}api_key=#{@api_key}")
      response = JSON.parse(Net::HTTP.get(uri))
      if response.is_a?(Hash)
        response = response.with_indifferent_access
        response[:data] ? response[:data] : response
      end
    end
    private

    def load_api(filename)
      @api = YAML.load_file(
        "#{Rails.root.to_s}/config/#{filename}.yml"
      ).with_indifferent_access
    end

    def replace_url(url, args)
      args.inject(url) do |replaced_url, (key, val)|
        replaced_url.gsub(/{#{key}}/, val)
      end
    end
  end
end
