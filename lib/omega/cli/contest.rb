# frozen_string_literal: true

module Omega
  class CLI
    module Contest
      def register_user(contest_name, user)
        contest = omega.contest(contest_name)
        puts contest.add_user(user)[:status]
      rescue StandardError => e
        puts "Error adding #{user}: #{e.message}"
      end

      def register_users(contest_name, user_file)
        users = File.readlines(user_file).map(&:strip)
        contest = omega.contest(contest_name)
        failed = []
        users.each do |user|
          puts "Adding #{user}..."
          contest.add_user(user)
        rescue StandardError => e
          puts "Error adding #{user}: #{e.message}"
          failed << user
        end
        puts "Failed users: \n- #{failed.join("\n- ")}"
      end

      def user_data(user)
        puts omega.user(user).full_data.to_yaml
      end

      def clarifications(contest_name, filter_open)
        clarifications = omega.clarifications(contest_name)
        clarifications.select! { |clar| clar[:answer].nil? || clar[:answer].empty? } if filter_open
        puts clarifications.to_yaml
      end

      def scoreboard(contest_name)
        score = omega.scoreboard(contest_name)
        score.simple_display.each_with_index { |s, i| puts "#{i + 1}.- #{s.values.join(': ')}" }
      rescue StandardError => e
        puts "#{contest_name}: #{e.message}"
      end

      def download_sources(contest_name, path)
        Dir.mkdir(path) unless File.directory?(path)
        contest = omega.contest(contest_name)
        contest.all_sources.each do |source|
          source.save_at(path)
        end
      end
    end
  end
end
