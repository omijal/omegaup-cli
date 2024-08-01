# frozen_string_literal: true

require_relative 'contest'
require_relative 'scoreboard'
require_relative 'user'
require_relative 'contest_run'
require 'json'
require 'nokogiri'

require 'httparty'

module Omega
  KAREL_LANGS = 'kp,kj'
  OMI_LANGS = 'c11-gcc,c11-clang,cpp11-gcc,cpp11-clang,cpp17-gcc,cpp17-clang,cpp20-gcc,cpp20-clang'
  ALL_LANGS = 'kp,kj,c11-gcc,c11-clang,cpp11-gcc,cpp11-clang,cpp17-gcc,cpp17-clang,cpp20-gcc,cpp20-clang,java,kt,py2,py3,rb,cs,pas,cat,hs,lua,go,rs,js'

  class OmegaError < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def message
      "#{@data[:errorname]}::#{@data[:errorcode]} >> #{@data[:error]}"
    end

    def errorname
      @data[:errorname]
    end

    def errorcode
      @data[:errorcode]
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
      body = ::JSON.parse(response.body, symbolize_names: true)

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

    def problem_details(problem_alias)
      post('/api/problem/details', { problem_alias: })
    end

    def create_group(name, description: nil, alias: nil)
      post('/api/group/create', name:, alias:, description:)
    end

    def create_contest(name:, short_name:, description:, start_time:, finish_time:,
                       public: false, penalty_calc_policy: 'sum', show_penalty: true,
                       points_decay_factor: '0', submissions_gap: '60', languages: ALL_LANGS, feedback: 'none',
                       penalty: '0', scoreboard: '100', penalty_type: 'none',
                       default_show_all_contestants_in_scoreboard:	false,
                       show_scoreboard_after:	true,
                       score_mode:	'partial',
                       needs_basic_information:	false,
                       requests_user_information:	'no',
                       contest_for_teams:	false)
      post('/api/contest/create/', {
             admin: true,
             admission_mode:	(public ? 'public' : 'private'),
             alias: short_name,
             archived:	false,
             opened:	false,
             penalty_calc_policy:,
             show_penalty:,
             title: name,
             description:,
             has_submissions:	false,
             start_time: start_time.to_time.to_i,
             finish_time:	finish_time.to_time.to_i,
             points_decay_factor:,
             submissions_gap:,
             languages:,
             feedback:,
             penalty:,
             scoreboard:,
             penalty_type:,
             default_show_all_contestants_in_scoreboard:,
             show_scoreboard_after:,
             score_mode:,
             needs_basic_information:,
             requests_user_information:,
             contest_for_teams:
           })
      contest(short_name)
    rescue OmegaError => e
      raise e unless e.errorname == 'aliasInUse'

      contest(short_name)
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

    def add_admin_group(contest, group)
      post('/api/contest/addGroupAdmin', { contest_alias: contest, group: })
    rescue OmegaError
      # Omega seems to have a bug
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
      data = post('/api/contest/runs/', { contest_alias: contest, offset:, rowcount: page_size })
      data[:runs].map { |run| ContestRun.new(self, run) }
    end

    def add_problem_to_contest(contest, problem, points = 100)
      post('/api/contest/addProblem', contest_alias: contest, problem_alias: problem, points:)
    end

    def add_user_to_group(group_name, username)
      post('/api/group/addUser', group_alias: group_name, usernameOrEmail: username)
    rescue OmegaError => e
      raise if e.errorname != 'identityInGroup'
    end

    def get_payload_from_response_by_id(response_body, id)
      page = Nokogiri::HTML(response_body)
      script = page.at_css("script##{id}")
      unless script
        raise OmegaError.new(errorname: 'ScrapingError', errorcode: 404,
                             error: "Script with id #{id} not found")
      end

      script_content = script.content
      # Extrayendo el contenido JSON del script
      begin
        ::JSON.parse(script_content, symbolize_names: true)
      rescue JSON::ParserError
        raise OmegaError.new(errorname: 'ScrapingError', errorcode: 500, error: 'Unable to parse JSON data')
      end
    end

    def scrap_get(endpoint, id = 'payload')
      url = "#{@config['endpoint']}#{endpoint}"
      response = self.class.get(url)
      unless response.success?
        raise OmegaError.new(errorname: 'HttpError', errorcode: response.code,
                             error: response.message)
      end

      body = get_payload_from_response_by_id(response.body, id)

      raise OmegaError, body if body[:error]

      body
    end
  end
end
