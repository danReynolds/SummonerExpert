# Setup controller tests with data from the API
shared_context 'spec setup' do
  let(:resources) do
    JSON.parse(File.read('api.json')).with_indifferent_access[:resources]
  end
  let(:params) do
    res = resources.detect do |res|
      res[:name] == "#{controller_class_name}/#{action}"
    end
    JSON.parse(res[:body][:text])
  end

  def response_body
    JSON.parse(response.body).with_indifferent_access
  end

  def speech
    JSON.parse(response.body).with_indifferent_access[:speech]
  end
end

# Override the indeterminate nature of the speech templates returned
shared_context 'determinate speech' do
  before :each do
    allow(ApiResponse).to receive(:random_response) do |responses|
      responses.first
    end
  end
end
