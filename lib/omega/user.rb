# frozen_string_literal: true

require_relative 'base'

module Omega
  class User < Base
    def full_data
      {
        data: @data,
        problems_solved:,
        resume: report
      }
    end

    def problems_solved
      @client.problems_solved(data[:username])[:problems]
    end

    def report
      data = { score: 0, count: 0 }
      problems_solved.each do |p|
        data[:score] += p[:difficulty] || 0
        data[:count] += 1
      end
      data
    end
  end
end
