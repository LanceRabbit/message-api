# frozen_string_literal: true
require 'google/apis/sheets_v4'
require 'singleton'

class Auth

  class << self
    extend Forwardable

    def_delegator :instance, :service
    # delegate :client => :instance
    # delegate %i[reply_message] => :client
  end

  include Singleton

  attr_reader :service

  def initialize
    # not work
    # @service = Google::Apis::SheetsV4::SheetsService.new {|config|
    #   config.authorization = settings
    # }
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = settings
    @service
  end

  private

    def settings
      scope = [Google::Apis::SheetsV4::AUTH_SPREADSHEETS]
      file = File.open("google-api-key.json", 'r')
      authorization = Google::Auth::ServiceAccountCredentials.make_creds({:json_key_io=> file, :scope => scope})
    end
end

# p Auth.service

