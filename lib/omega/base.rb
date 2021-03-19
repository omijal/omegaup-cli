# frozen_string_literal: true

module Omega
  class Base
    attr_reader :data

    def initialize(client, data)
      @client = client
      @data = data
    end
  end
end
