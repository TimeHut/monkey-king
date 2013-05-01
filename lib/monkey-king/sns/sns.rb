# encoding: utf-8
require 'monkey-king/sns/strategy'
require 'monkey-king/sns/strategies/facebook'
require 'monkey-king/sns/strategies/twitter'
require 'monkey-king/sns/strategies/weibo'
require 'monkey-king/sns/signed_request_parser'

module MonkeyKing
  module SNS
  
    SUPPORTED_PROVIDERS = %w[facebook twitter weibo]

    def self.supports? provider
      SUPPORTED_PROVIDERS.include? provider.to_s
    end

    def self.provider_from_hash provider, credentials
      credentials = JSON.parse credentials if credentials.is_a?(String)

      provider_class = MonkeyKing::SNS::Strategies.const_get(provider.to_s.capitalize)
      provider_class.new credentials
    end

  end
end