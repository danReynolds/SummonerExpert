class ApiResponse
  API_RESPONSES = YAML.load_file(
    "#{Rails.root.to_s}/config/api_responses.yml"
  ).with_indifferent_access

  class << self
    def replace_response(response, args)
      replaced_response = args.inject(response) do |replaced_response, (key, val)|
        prefix_match = replaced_response.match(/{:(.*):#{key}}/)
        entity_val = Entities.send(key, val)
        entity_val = "#{prefix_match.captures.first} #{entity_val}" if prefix_match
        replaced_response.gsub(/{(?::.*:)?#{key}}/, entity_val)
      end
      replaced_response.gsub(/{(?::|\w)+}/, '').split(' ').join(' ').gsub(/\s\./, '.')
    end

    def get_response(namespace, args = {}, responses = API_RESPONSES)
      if namespace.class == Hash && responses.class == HashWithIndifferentAccess
        key = namespace.keys.first
        get_response(namespace[key] || namespace, args, responses[key] || responses)
      else
        if responses.class == HashWithIndifferentAccess
          replace_response(random_response(responses[namespace]), args)
        else
          replace_response(random_response(responses), args)
        end
      end
    end

    # Return the arguments for an API response given a Filterable filter
    def filter_args(filter)
      {
        list_position: filter.list_position.en.ordinate,
        real_size: filter.real_size.en.numwords,
        requested_size: filter.requested_size.en.numwords,
        filtered_size: filter.filtered_size.en.numwords,
        list_order: filter.list_order,
        filtered_position_offset: (filter.list_position + filter.filtered_size - 1).en.ordinate
      }
    end

    private

    def random_response(responses)
      responses.sample
    end
  end
end
