module CompetitionApi
  class CompetitionApi < ExternalApi
    @api = load_api('competition_api')

    class << self
      def get_standings(args)
        url = "#{replace_url(@api[:lcs][:standings], args)}"
        session = Capybara::Session.new(:poltergeist)
        session.visit(url)
        binding.pry
        Nokogiri::HTML(session.html).css('.team-name').map do |team|
          team.children.text.strip
        end
      end
    end
  end
end
