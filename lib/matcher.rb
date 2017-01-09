module Matcher
  class Matcher
    include Amatch

    SIMILARITY_THRESHOLD = 0.45
    AGGREGATE_SIMILARITY_THRESHOLD = 0.9

    class Match
      attr_accessor :similarity, :result

      def initialize(args)
        @similarity = args[:similarity]
        @result = args[:result]
      end
    end

    def initialize(pattern)
      @comparator = Levenshtein.new(pattern.downcase)
    end

    def find_match(objects, threshold = SIMILARITY_THRESHOLD, key = nil)
      match = objects.inject(Hash.new) do |acc, obj|
        query = key ? obj.send(key) : obj
        similarity = @comparator.similar(query.downcase)

        acc.tap do |acc|
          if (acc[:similarity].nil? || acc[:similarity] < similarity) && similarity >= threshold
            acc.merge!(
              similarity: similarity,
              result: obj
            )
          end
        end
      end
      match[:similarity] ? Match.new(match) : nil
    end
  end
end
