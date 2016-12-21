require 'rails_helper'

describe ChampionsController, type: :controller do
  let(:resources) do
    JSON.parse(File.read('api.json')).with_indifferent_access[:resources]
  end
  let(:params) do
    res = resources.detect do |res|
      res[:name] == "champions/#{action}"
    end
    JSON.parse(res[:body][:text])
  end

  def speech
    JSON.parse(response.body).with_indifferent_access[:speech]
  end

  describe 'POST title' do
    let(:action) { :title }

    it 'should return the champions title' do
      post action, params
      expect(speech).to eq "Sona's title is Maven of the Strings"
    end
  end
end
