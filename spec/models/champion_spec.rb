require 'rails_helper'

RSpec.describe Champion, type: :model do
  describe '#new' do
    let(:name) { '' }

    before :each do
      @champion = Champion.new(name: name)
    end

    context 'without a name provided' do
      it 'should specify that a name for the champion was not provided' do
        expect(@champion.valid?).to eq false
        expect(@champion.error_message).to eq 'name of champion was not provided.'
      end
    end

    context 'with an invalid name provided' do
      let(:name) { 'test' }

      it 'should specify that an invalid champion name was provided' do
        expect(@champion.valid?).to eq false
        expect(@champion.error_message).to eq 'name provided is not a valid champion name, to the best of my knowledge.'
      end
    end
  end

  describe '#find_by_role' do
    let(:champion) { Champion.new(name: 'Bard') }

    context 'with a role provided' do
      let(:role) { 'Support' }
      context 'with a matching role' do
        it 'should return the data for that role' do
          expect(champion.find_by_role(role)).to eq(champion.roles.first)
        end
      end

      context 'without a matching role' do
        let(:role) { 'Made up role' }

        it 'should return no data' do
          expect(champion.find_by_role(role)).to eq nil
        end
      end
    end

    context 'without a role provided' do
      let(:role) { '' }

      context 'with multiple roles' do
        before :each do
          champion.roles << champion.roles.first
        end

        it 'should return no data' do
          expect(champion.find_by_role(role)).to eq nil
        end
      end

      context 'with only one role' do
        it 'should return the data for that role' do
          expect(champion.find_by_role(role)).to eq(champion.roles.first)
        end
      end
    end
  end
end
