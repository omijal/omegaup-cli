# frozen_string_literal: true

require_relative 'base'

module Omega
  class ContestRun < Base
    def details
      @details ||= @client.run_details(@data[:guid])
    end

    def source_code
      details[:source]
    end

    def save_at(path)
      File.write("#{path}/#{@data[:guid]}.yaml", { details: details, data: @data }.to_yaml)
    end
  end
end
