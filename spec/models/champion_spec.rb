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
end
