# frozen_string_literal: true

require 'singleton'
require 'forwardable'

class Bot
  class << self
    extend Forwardable

    def_delegator :instance, :client
    # delegate :client => :instance
    # delegate %i[reply_message] => :client
  end

  include Singleton

  attr_reader :client

  def initialize
    @client = Line::Bot::Client.new { |config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end

# p Bot.singleton_methods
# p Bot.client
