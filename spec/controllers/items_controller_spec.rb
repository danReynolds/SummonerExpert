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
      "Here are the stats for Blade of the Ruined King:\n+25 Attack Damage\n+40% Attack Speed\n+10% Life Steal\nUNIQUE Passive: Basic attacks deal 8% of the target's current Health in bonus physical damage (max 60 vs. monsters and minions) on hit. Life Steal applies to this damage.\nUNIQUE Active: Deals 10% of target champion's maximum Health (min. 100) as physical damage, heals for the same amount, and steals 25% of the target's Movement Speed for 3 seconds (90 second cooldown).\n\nHere is the cost analysis: \nCost: 3400\nWorth: 5250\nEfficiency: 1.544\nIgnored Stats: \n- UNIQUE Active\n \nThis item is gold efficient."
    end

    it_should_behave_like 'load item'

    context 'with no name match' do
      before :each do
        @name = 'test item'
        allow(controller).to receive(:item_params).and_return(item: @name)
      end

      it 'should indicate the item was not found' do
        post action, params
        expect(speech).to eq controller.send(
          :item_not_found_response,
          @name
        )[:speech]
      end
    end

    context 'with no item specified' do
      before :each do
        allow(controller).to receive(:item_params).and_return(item: '')
      end

      it 'should indicate that no item was specified' do
        post action, params
        expect(speech).to eq controller.send(
          :no_item_specified_response
        )[:speech]
      end
    end

    context 'with exact name match' do
      it 'should return the description of the item' do
        post action, params
        expect(speech).to eq response_text
      end
    end

    context 'with fuzzy name match' do
      before :each do
        allow(controller).to receive(:item_params).and_return(
          item: 'Blade of the Ruined'
        )
      end

      it 'should match the item' do
        post action, params
        expect(speech).to eq response_text
      end
    end
  end
end
