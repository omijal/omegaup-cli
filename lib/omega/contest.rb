# frozen_string_literal: true

require_relative 'base'

module Omega
  class Contest < Base
    def scoreboard
      @client.scoreboard(data[:alias])
    end

    def add_user(user)
      if user.is_a?(String)
        @client.add_user_to_contest(user, data[:alias])
      else
        @client.add_user_to_contest(user.data[:username], data[:alias])
      end
    end

    def observe
      last = current = scoreboard
      sleep(5)
      loop do
        current = scoreboard
        last.users.each do |score|
          puts score.username
          current_score = current.score_for(score.username)
          score.problems.each do |problem|
            name = problem[:alias]
            current_problem = current_score.score_for(name)
            last_points = problem[:points]
            current_points = current_problem[:points]
            puts "  #{name}::#{last_points} >> #{current_points}"
            yield(contest_name, score.username, name, current_points, last_points) if current_points != last_points
          end
          puts '-' * 60
        end
        last = current
        sleep(15)
      end
    end
  end
end
