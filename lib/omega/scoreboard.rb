# frozen_string_literal: true

require_relative 'base'

module Omega
  class ScoreboardEntry < Base
    attr_accessor :problems
    attr_reader :username

    def initialize(client, entry)
      @username = entry[:username]
      @client = client
      @problems = entry[:problems] || []
      @data = entry
    end

    def merge(score)
      result = clone
      result.problems += score.problems
      result.data[:total][:points] += score.data[:total][:points]
      result
    end

    def simple_display
      {
        username: @data[:username],
        score: @data[:total][:points]
      }
    end

    def <=>(other)
      other.data[:total][:points] <=> @data[:total][:points]
    end

    def score_for(name)
      problems.each do |problem|
        return problem if problem[:alias] == name
      end
      nil
    end
  end

  class Scoreboard < Base
    def initialize(client, data)
      @client = client
      @data = data.dup
      @data[:ranking] = {}
      data[:ranking].each do |entry|
        @data[:ranking][entry[:username]] = ScoreboardEntry.new(client, entry)
      end
    end

    def merge(board)
      result = clone
      board.data[:ranking].each do |user, score|
        result.data[:ranking][user] =
          result.data[:ranking][user].nil? ? score : result.data[:ranking][user].merge(score)
      end
      result
    end

    def simple_display
      users.map(&:simple_display)
    end

    def score_for(user)
      @data[:ranking][user]
    end

    def users
      @data[:ranking].values.sort
    end
  end
end
