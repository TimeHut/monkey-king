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

      klass = MonkeyKing::SNS::Strategies.const_get(provider.to_s.capitalize)
      klass.new credentials
    end

    def self.provider_with_random_token provider
      provider_from_hash provider, token: 'faketoken', secret: 'fakesecret'
    end

    def self.facebook_avatar uid
      MonkeyKing::SNS::Strategies::Facebook.picture uid, width: 150, height: 150
    end

    def self.parse_signed_request provider, request
      secret = MonkeyKing.config.app_secret provider
      MonkeyKing::SNS::SignedRequestParser.new(secret).parse request
    end

  end
end