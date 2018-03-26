require 'rails_helper'

RSpec.describe MatchHelper, type: :model do

  describe '#initialize_current_match' do
    before :each do
      match_data = JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][:current_match]
      @match = MatchHelper.initialize_current_match(match_data)
      @team = @match.team1
      @performances = @team.summoner_performances
      @top_performance = @performances.find { |performance| performance.role === 'TOP' }
      @jungle_performance = @performances.find { |performance| performance.role === 'JUNGLE' }
      @mid_performance = @performances.find { |performance| performance.role === 'MIDDLE' }
      @adc_performance = @performances.find { |performance| performance.role === 'DUO_CARRY' }
      @support_performance = @performances.find { |performance| performance.role === 'DUO_SUPPORT' }
    end

    it 'should assign roles to the summoners' do
      expect(@top_performance).to_not be_nil
      expect(@jungle_performance).to_not be_nil
      expect(@mid_performance).to_not be_nil
      expect(@adc_performance).to_not be_nil
      expect(@support_performance).to_not be_nil
    end
  end

  describe '#create_match' do
    before :each do
      match_data = JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][:match]
      MatchHelper.create_match(match_data)
      @match = Match.first
      @team = @match.team1
      @performances = @team.summoner_performances
      @top_performance = @performances.where(role: 'TOP').first
      @jungle_performance = @performances.where(role: 'JUNGLE').first
      @mid_performance = @performances.where(role: 'MIDDLE').first
      @adc_performance = @performances.where(role: 'DUO_CARRY').first
      @support_performance = @performances.where(role: 'DUO_SUPPORT').first
    end

    def fix_roles
      MatchHelper.fix_team_roles(@performances)
      @performances.each { |performance| performance.save! }
    end

    def check_roles
      expect(@top_performance.reload.role).to eq 'TOP'
      expect(@jungle_performance.reload.role).to eq 'JUNGLE'
      expect(@mid_performance.reload.role).to eq 'MIDDLE'
      expect(@adc_performance.reload.role).to eq 'DUO_CARRY'
      expect(@support_performance.reload.role).to eq 'DUO_SUPPORT'
    end

    it 'should create a match with the necessary components' do
      expect(Match.count).to eq 1
      expect(Team.count).to eq 2
      expect(SummonerPerformance.count).to eq 10
      expect(Ban.count).to eq 10
      expect(Summoner.count).to eq 10
    end

    context 'with not all lanes assigned' do
      it 'should try fixing roles' do
        @adc_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Tristana').id)
        expect(MatchHelper.team_roles_missing?(@team.reload.summoner_performances)).to eq true
      end
    end

    context 'with not all lanes assigned' do
      it 'should not try fixing roles' do
        expect(MatchHelper.team_roles_missing?(@team.reload.summoner_performances)).to eq false
      end
    end

    context 'with one lane unassigned' do
      describe 'with an unassigned bot lane' do
        context 'with the ADC unassigned' do
          before :each do
            @adc_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Tristana').id)
          end

          it 'should assign the missing role to the ADC' do
            fix_roles
            check_roles
          end
        end

        context 'with the support unassigned' do
          before :each do
            @support_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Tristana').id)
          end

          it 'should assign the missing role to support' do
            fix_roles
            check_roles
          end
        end

        context 'with champions that normally play those roles' do
          before :each do
            @adc_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Tristana').id)
            @support_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Blitzcrank').id)
          end

          it 'should assign the roles to the likely champions' do
            fix_roles
            check_roles
          end
        end

        context 'with a champion that normally plays ADC' do
          before :each do
            @adc_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Tristana').id)
            @support_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Renekton').id)
          end

          it 'should assign the roles to the likely champions' do
            fix_roles
            check_roles
          end
        end

        context 'with a champion that normally plays Support' do
          before :each do
            @adc_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Azir').id)
            @support_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Blitzcrank').id)
          end

          it 'should assign the roles to the likely champions' do
            fix_roles
            check_roles
          end
        end

        context 'with champions that do not play those roles' do
          before :each do
            @adc_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Nasus').id)
            @support_performance.update!(role: 'BOTTOM', champion_id: Champion.new(name: 'Mordekaiser').id)
          end

          context 'with both using conventional spells' do
            before :each do
              @adc_performance.update!(spell1_id: Spell.new(name: 'Heal').id, spell2_id: Spell.new(name: 'Flash').id)
              @support_performance.update!(spell1_id: Spell.new(name: 'Exhaust').id, spell2_id: Spell.new(name: 'Flash').id)
            end

            it 'should assign the roles based on spells' do
              fix_roles
              check_roles
            end
          end

          context 'with one using conventional spells' do
            before :each do
              @adc_performance.update!(spell1_id: Spell.new(name: 'Heal').id, spell2_id: Spell.new(name: 'Flash').id)
              @support_performance.update!(spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id)
            end

            it 'should assign the roles based on spells' do
              fix_roles
              check_roles
            end
          end

          context 'with neither using conventional spells' do
            context 'with one having higher assists' do
              before :each do
                @adc_performance.update!(assists: 0, spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id)
                @support_performance.update!(assists: 100000, spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id)
              end

              it 'should assign the roles based on assists' do
                fix_roles
                check_roles
              end
            end

            context 'with neither having higher assists' do
              before :each do
                @adc_performance.update!(assists: 0, spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id)
                @support_performance.update!(assists: 0, spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id)
              end

              it 'should assign the roles to the remaining undetermined performances' do
                fix_roles
                expect(@performances.reload.map(&:role).uniq.length).to eq 5
              end
            end
          end
        end
      end

      describe 'with an unassigned top lane' do
        context 'with a conventional top laner' do
          before :each do
            @top_performance.update!(champion_id: Champion.new(name: 'Nasus').id, role: 'MIDDLE')
            @mid_performance.update!(champion_id: Champion.new(name: 'Ahri').id, role: 'MIDDLE')
          end

          it 'should assign the role to the likely champion' do
            fix_roles
            check_roles
          end
        end

        context 'with an unconventional top laner' do
          before :each do
            @top_performance.update!(champion_id: Champion.new(name: 'Tristana').id, role: 'MIDDLE')
            @mid_performance.update!(champion_id: Champion.new(name: 'Ahri').id, role: 'MIDDLE')
          end

          it 'should assign the roles to the remaining undetermined performances' do
            fix_roles
            expect(@performances.reload.map(&:role).uniq.length).to eq 5
          end
        end
      end

      describe 'with an unassigned mid lane' do
        context 'with a conventional mid laner' do
          before :each do
            @top_performance.update!(champion_id: Champion.new(name: 'Nasus').id, role: 'TOP')
            @mid_performance.update!(champion_id: Champion.new(name: 'Ahri').id, role: 'TOP')
          end

          it 'should assign the role to the likely champion' do
            fix_roles
            check_roles
          end
        end

        context 'with an unconventional mid laner' do
          before :each do
            @top_performance.update!(champion_id: Champion.new(name: 'Tristana').id, role: 'TOP')
            @mid_performance.update!(champion_id: Champion.new(name: 'Jax').id, role: 'TOP')
          end

          it 'should assign the roles to the remaining undetermined performances' do
            fix_roles
            expect(@performances.reload.map(&:role).uniq.length).to eq 5
          end
        end
      end

      describe 'with an unassigned jungler' do
        context 'with a conventional jungler' do
          before :each do
            @jungle_performance.update!(champion_id: Champion.new(name: 'Lee Sin').id, role: 'TOP')
            @top_performance.update!(champion_id: Champion.new(name: 'Renekton').id, role: 'TOP')
          end

          it 'should assign the role to the likely champion' do
            fix_roles
            check_roles
          end
        end

        context 'with an unconventional jungler' do
          before :each do
            @jungle_performance.update!(champion_id: Champion.new(name: 'Azir').id, role: 'TOP')
            @top_performance.update!(champion_id: Champion.new(name: 'Renekton').id, role: 'TOP')
          end

          context 'with conventional jungler spells' do
            before :each do
              @jungle_performance.update!(spell1_id: Spell.new(name: 'Smite').id, spell2_id: Spell.new(name: 'Flash').id)
            end

            it 'should assign the role based on summoner spells' do
              fix_roles
              check_roles
            end
          end

          context 'without conventional jungler spells' do
            before :each do
              @jungle_performance.update!(spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id)
            end

            it 'should assign the roles to the remaining undetermined performances' do
              fix_roles
              expect(@performances.reload.map(&:role).uniq.length).to eq 5
            end
          end
        end
      end
    end

    context 'with multiple lanes unassigned' do
      context 'with all champions unique to their roles' do
        before :each do
          @top_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Renekton').id)
          @jungle_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Lee Sin').id)
          @mid_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Azir').id)
          @adc_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Tristana').id)
          @support_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Bliltzcrank').id)
        end

        it 'should determine roles based on the champions' do
          fix_roles
          check_roles
        end
      end

      context 'with multiple pairs of roles assigned' do
        before :each do
          @top_performance.update!(role: 'TOP', champion_id: Champion.new(name: 'Poppy').id)
          @jungle_performance.update!(
            role: 'DUO_SUPPORT', champion_id: Champion.new(name: 'Hecarim').id,
            spell1_id: Spell.new(name: 'Smite').id, spell2_id: Spell.new(name: 'Ghost').id
          )
          @mid_performance.update!(
            role: 'DUO_SUPPORT', champion_id: Champion.new(name: 'Morgana').id,
            spell1_id: Spell.new(name: 'Exhaust').id, spell2_id: Spell.new(name: 'Flash').id
          )
          @adc_performance.update!(
            role: 'DUO_CARRY', champion_id: Champion.new(name: 'Lucian').id,
            spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id,
            assists: 1
          )
          @support_performance.update!(
            role: 'DUO_CARRY', champion_id: Champion.new(name: 'Xayah').id,
            spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Flash').id,
            assists: 1000
          )
        end

        it 'should determine roles based on the champions' do
          fix_roles
          check_roles
        end
      end

      context 'with all champions defined by their roles and spells' do
        before :each do
          @top_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Renekton').id)
          @jungle_performance.update!(
            role: 'MIDDLE', champion_id: Champion.new(name: 'Nasus').id,
            spell1_id: Spell.new(name: 'Teleport').id, spell2_id: Spell.new(name: 'Smite').id
          )
          @mid_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Azir').id)
          @adc_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Tristana').id)
          @support_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Bliltzcrank').id)
        end

        it 'should determine roles based on the champions and spells' do
          fix_roles
          check_roles
        end
      end

      context 'with champions not identifiable by their roles and spells' do
        before :each do
          @top_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Renekton').id)
          @jungle_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Renekton').id)
          @mid_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Renekton').id)
          @adc_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Renekton').id)
          @support_performance.update!(role: 'MIDDLE', champion_id: Champion.new(name: 'Renekton').id)
        end

        it 'should assign the roles to the remaining undetermined performances' do
          fix_roles
          expect(@performances.reload.map(&:role).uniq.length).to eq 5
        end
      end
    end
  end
end
