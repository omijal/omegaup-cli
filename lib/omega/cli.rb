# frozen_string_literal: true

require_relative '../omega'
require_relative 'cli/contest'
require 'optimist'

module Omega
  class CLI
    attr_reader :omega

    include Omega::CLI::Contest
    SUB_COMMANDS = %w[
      register-users
      user
      scoreboard
      create-contest
      add-problem
      help
    ].freeze

    def print_help
      puts %(
OmegaUp CLI. Developed by OMIJal https://github.com/omijal/omegaup-cli.
Tool for interacting with omegaup from CLI and available throug ruby gems.
Commands:
 - register-users  Add a user or a bunch of users to the a contest.
 - user            Generates a dump of the user data in yml format.
 - scoreboard      Gets contest scoreboard with users and score.
 - clarifications  Gets contest clarifications.
Parametes:
 --contest         Contest name
 --user            Username or email
 --user-file       A file path containing a list of user one per line without
                   header
 --open            Filter to only open clarifications
Setup:
You need to add two env variables with your omegaup credentials.
OMEGAUP_URL  *Optional* This is intended for development purpose, it will target
                        to https://omegau.com by default.
OMEGAUP_USER *Required* Your OmegaUp Username or Email
OMEGAUP_PASS *Required* Your OmegaUp Password
      )
    end

    def initialize(_)
      @cmd = ARGV.shift

      @cmd_opts = case @cmd
                  when 'register-users'
                    Optimist.options do
                      opt :contest, 'Contest ShortName or identifier', type: :string
                      opt :user, 'Username or email', type: :string
                      opt :user_file, 'A file containing the users list one per line and without header', type: :string
                    end
                  when 'user'
                    Optimist.options do
                      opt :user, 'Username or email', type: :string
                    end
                  when 'scoreboard'
                    Optimist.options do
                      opt :contest, 'Contest ShortName or identifier', type: :string
                    end
                  when 'clarifications'
                    Optimist.options do
                      opt :contest, 'Contest ShortName or identifier', type: :string
                      opt :open, 'Filter to only open clars'
                    end
                  # when 'create-contest'
                  #   Optimist.options do
                  #     opt :contest, 'Contest ShortName or identifier', type: :string
                  #   end
                  # when 'add-problem'
                  #   Optimist.options do
                  #     opt :contest, 'Contest ShortName or identifier', type: :string
                  #     opt :problem, type: :string
                  #   end
                  else
                    print_help
                    exit(0)
                  end
    end

    def login
      config = {
        'omega' => {
          'endpoint' => ENV['OMEGAUP_URL'] || 'https://omegaup.com',
          'user' => ENV['OMEGAUP_USER'],
          'pass' => ENV['OMEGAUP_PASS']
        }
      }

      @omega = Omega::Client.new(config['omega'])
      @omega.login
    end

    def execute
      login
      case @cmd
      when 'register-users'
        register_user(@cmd_opts[:contest], @cmd_opts[:user]) if @cmd_opts[:user]
        register_users(@cmd_opts[:contest], @cmd_opts[:user_file]) if @cmd_opts[:user_file]
      when 'user'
        user_data(@cmd_opts[:user])
      when 'scoreboard'
        scoreboard(@cmd_opts[:contest])
      when 'clarifications'
        clarifications(@cmd_opts[:contest], @cmd_opts[:open])
      end
    end
  end
end
