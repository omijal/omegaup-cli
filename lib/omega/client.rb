# frozen_string_literal: true

require_relative 'contest'
require_relative 'scoreboard'
require_relative 'user'
require_relative 'contest_run'

require 'httparty'

module Omega
  class OmegaError < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def message
      "#{@data[:errorname]}::#{@data[:errorcode]} >> #{@data[:error]}"
    end
  end

  class Client
    include HTTParty

    def initialize(conf)
      @config = conf
    end

    def perform_request(method, endpoint, data, retried = false)
      url = "#{@config['endpoint']}#{endpoint}"
      response = self.class.send(method, url, body: data)
      body = JSON.parse(response.body, symbolize_names: true)

      if body[:errorcode] == 401 && !retried
        login
        return perform_request(method, endpoint, data, true)
      end
      raise OmegaError, body if body[:error]

      body
    end

    def post(endpoint, data)
      perform_request(:post, endpoint, data)
    end

    def login
      data = post('/api/user/login',
                  usernameOrEmail: @config['user'],
                  password: @config['pass'])
      @token = data[:auth_token]
      self.class.default_cookies.add_cookies('ouat' => data[:auth_token])
    end

    def open_contest(name)
      post('/api/contest/open/', { contest_alias: name })
    end

    def contest(name)
      data = post('/api/contest/details/', { contest_alias: name })
      Contest.new(self, data)
    rescue OmegaError => e
      raise unless e.data[:errorname] == 'userNotAllowed'

      open_contest(name)
      retry
    end

    def scoreboard(name)
      data = post('/api/contest/scoreboard/', { contest_alias: name })
      Scoreboard.new(self, data)
    end

    def clarifications(name)
      data = post('/api/contest/clarifications/', { contest_alias: name })
      data[:clarifications]
    end

    def respond_clarif(id, response)
      post('/api/clarification/update/', { clarification_id: id, answer: response })
    end

    def user(user)
      data = post('/api/user/profile/', { username: user })
      User.new(self, data)
    end

    def add_user_to_contest(user, contest)
      post('/api/contest/addUser', { contest_alias: contest, usernameOrEmail: user })
    end

    def problems_solved(user)
      post('/api/user/problemsSolved/', { username: user })
    end

    def run_details(run)
      post('/api/run/details/', { run_alias: run })
    end

    def contest_runs(contest, offset, page_size)
      data = post('/api/contest/runs/', { contest_alias: contest, offset: offset, rowcount: page_size })
      data[:runs].map { |run| ContestRun.new(self, run) }
    end
  end
end
