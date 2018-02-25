require 'rails_helper'

RSpec.describe SummonerPerformance, type: :model do
  describe '#not_remake' do
    context 'with a remake' do
      before :each do
        @match = create(:match, game_duration: 180)
      end

      it 'should not return any summoner performances' do
        expect(@match.summoner_performances.joins(:match).not_remake.length).to eq 0
      end
    end

    context 'with non-remakes' do
      before :each do
        @match = create(:match)
      end

      it 'should return summoner performances' do
        expect(@match.summoner_performances.joins(:match).not_remake.length).to eq 10
      end
    end
  end

  describe '#current_season' do
    context 'with pre-season games' do
      before :each do
        @match = create(:match)
        @match.summoner_performances.each do |performance|
          performance.update_attribute(:created_at, Date.new(2015, 12, 12))
        end
      end

      it 'should not return any summoner performances' do
        expect(@match.summoner_performances.joins(:match).current_season.length).to eq 0
      end
    end

    context 'with non-remakes' do
      before :each do
        @match = create(:match)
      end

      it 'should return summoner performances' do
        expect(@match.summoner_performances.joins(:match).current_season.length).to eq 10
      end
    end
  end

  describe '#timeframe' do
    before :each do
      @match = create(:match)
    end

    context 'with both a start time and an end time' do
      context 'with matches within the timeframe' do
        it 'should not return any summoner performances' do
          expect(
            @match.summoner_performances.joins(:match)
              .timeframe(Date.new(2015, 12, 12), Date.new(3000, 12, 12)).length
          ).to eq 10
        end
      end

      context 'with matches outside the timeframe' do
        it 'should not return any summoner performances' do
          expect(
            @match.summoner_performances.joins(:match)
              .timeframe(Date.new(2500, 12, 12), Date.new(3000, 12, 12)).length
          ).to eq 0
        end
      end
    end

    context 'with only a start time' do
      context 'with matches within the timeframe' do
        it 'should not return any summoner performances' do
          expect(
            @match.summoner_performances.joins(:match).timeframe(Date.new(2015, 12, 12)).length
          ).to eq 10
        end
      end

      context 'with matches outside the timeframe' do
        it 'should not return any summoner performances' do
          expect(
            @match.summoner_performances.joins(:match)
              .timeframe(Date.new(2500, 12, 12)).length
          ).to eq 0
        end
      end
    end

    context 'with only an end time' do
      context 'with matches within the timeframe' do
        it 'should not return any summoner performances' do
          expect(
            @match.summoner_performances.joins(:match).timeframe(nil, Date.new(3000, 12, 12)).length
          ).to eq 10
        end
      end

      context 'with matches outside the timeframe' do
        it 'should not return any summoner performances' do
          expect(
            @match.summoner_performances.joins(:match)
              .timeframe(nil, Date.new(1500, 12, 12)).length
          ).to eq 0
        end
      end
    end
  end
end
