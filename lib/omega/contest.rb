# frozen_string_literal: true

require_relative 'base'
require_relative 'contest_run'

module Omega
  class Contest < Base
    def scoreboard
      @client.scoreboard(data[:alias])
    end

    def runs(offset = 0, page_size = 100)
      @client.contest_runs(data[:alias], offset, page_size)
    end

    def all_sources
      sources = []
      offset = 0
      bach = runs

      until bach.empty?
        sources += bach
        offset += bach.size
        bach = runs(offset)
      end

      sources
    end

    def add_user(user)
      if user.is_a?(String)
        @client.add_user_to_contest(user, data[:alias])
      else
        @client.add_user_to_contest(user.data[:username], data[:alias])
      end
    end

    def clarifications
      @client.clarifications(data[:alias])
    end

    def observe(score_notifier, clar_noritifer)
      last = current = scoreboard
      sleep(5)
      Thread.new do
        loop do
          clarifications.select { |clar| clar[:answer].nil? || clar[:answer].empty? }
                        .each { |clar| clar_noritifer.call(clar) }
          sleep(300)
        rescue StandardError => ex
          puts ex.message
          sleep(3000)
        end
      end
      loop do
        current = scoreboard
        last.users.each do |score|
          # puts score.username
          current_score = current.score_for(score.username)
          score.problems.each do |problem|
            name = problem[:alias]
            current_problem = current_score.score_for(name)
            last_points = problem[:points]
            current_points = current_problem[:points]
            score_notifier.call(data[:alias], score.username, name, current_points, last_points, data[:alias]) if current_points != last_points
          end
        end
        # puts '-' * 60
        last = current
        sleep(15)
      rescue StandardError => ex
        puts ex.message
        sleep(3000)
      end
    end
  end
end
