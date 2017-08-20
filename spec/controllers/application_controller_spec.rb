require 'rails_helper'
require 'spec_contexts.rb'

describe ApplicationController, type: :controller do
  describe 'POST patch' do
    include_context 'spec setup'
    include_context 'determinate speech'

    let(:action) { :patch }

    it 'should return the current patch' do
      post action, params: params
      expect(speech).to eq 'All data is currently based off of patch 7.14.'
    end
  end

  describe 'POST status' do
    let(:action) { :status }

    it 'should indicate that the API is up' do
      post action
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['success']).to eq(true)
    end
  end
end
