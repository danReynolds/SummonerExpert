require 'rails_helper'
require 'spec_contexts.rb'

describe ItemsController, type: :controller do
  include_context 'spec setup'
  include_context 'determinate speech'

  before :each do
    allow(controller).to receive(:item_params).and_return(item_params)
  end

  describe 'POST build' do
    let(:action) { :build }
    let(:item_params) do
      { name: 'Blade of the Ruined King' }
    end

    context 'when it builds from something' do
      it 'should specify the items needed to build the item' do
        post action, params: params
        expect(speech).to eq 'The items used to build Blade of the Ruined King are Bilgewater Cutlass and Recurve Bow.'
      end
    end

    context 'when it does not build from something' do
      before :each do
        item_params[:name] = 'Boots of Speed'
      end

      it 'should specify that the item does not build from anything' do
        post action, params: params
        expect(speech).to eq 'Boots of Speed does not build from anything, from what I can tell.'
      end
    end
  end

  describe 'POST description' do
    let(:action) { :description }
    let(:item_params) do
      { name: 'Guardian Angel' }
    end

    it 'should provide a comprehensive breakdown of the item' do
      post action, params: params
      expect(speech).to eq "I have seen many champions use Guardian Angel on the field of battle. It costs 2400 gold and can be sold for 960. Here is what it does: +40 Attack Damage +30 Armor UNIQUE Passive: Upon taking lethal damage, restores 50% of base Health and 30% of maximum Mana after 4 seconds of stasis (300 second cooldown)."
    end
  end
end
