class ExternalApi
  class << self
    attr_accessor :api

    def fetch_response(endpoint, error_codes = [])
      append_symbol = endpoint.include?('?') ? '&' : '?'
      uri = URI("#{endpoint}#{append_symbol}api_key=#{@api_key}")
      response = Net::HTTP.get_response(uri)
      code = response.code.to_i

      raise Exception.new({ uri: endpoint, code: code }) if code != 200

      body = JSON.parse(response.body)
      if body.is_a?(Hash)
        body = body.with_indifferent_access
        body = body[:data] if body[:data]
      end
      body
    end

    private

    def load_api(filename)
      @api = YAML.load_file(
        "#{Rails.root.to_s}/config/#{filename}.yml"
      ).with_indifferent_access
    end

    def replace_url(url, args)
      args.inject(url) do |replaced_url, (key, val)|
        replaced_url.gsub(/{#{key}}/, val.to_s)
      end
    end
  end
end
