require 'rails_helper'

describe ItemsController, type: :controller do
  let(:resources) do
    JSON.parse(File.read('api.json')).with_indifferent_access[:resources]
  end
  let(:params) do
    res = resources.detect do |res|
      res[:name] == "items/#{action}"
    end
    JSON.parse(res[:body][:text])
  end

  def speech
    JSON.parse(response.body).with_indifferent_access[:speech]
  end

  shared_examples 'load item' do
    it 'should load the item' do
      expect(controller).to receive(:load_item).and_call_original
      post action, params
    end
  end

  describe 'POST show' do
    let(:action) { :show }
    let(:response_text) do
      "Here are the stats for Blade of the Ruined King:\n +25 Attack Damage\n+40% Attack Speed\n+10% Life Steal\nUNIQUE Passive: Basic attacks deal 8% of the target's current Health in bonus physical damage (max 60 vs. monsters and minions) on hit. Life Steal applies to this damage.\nUNIQUE Active: Deals 10% of target champion's maximum Health (min. 100) as physical damage, heals for the same amount, and steals 25% of the target's Movement Speed for 3 seconds (90 second cooldown)."
    end

    it_should_behave_like 'load item'

    it 'should return the description of the item' do
      post action, params
      expect(speech).to eq response_text
    end
  end
end
