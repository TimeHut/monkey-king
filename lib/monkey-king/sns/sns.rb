# encoding: utf-8
require 'monkey-king/sns/strategy'
require 'monkey-king/sns/strategies/facebook'
require 'monkey-king/sns/strategies/weibo'
require 'monkey-king/sns/strategies/qq_connect'
require 'monkey-king/sns/strategies/phone'
require 'monkey-king/sns/strategies/wechat'
require 'monkey-king/sns/signed_request_parser'
require 'monkey-king/sns/strategies/apple'

module MonkeyKing
  module SNS

    def self.provider_from_hash provider, credentials, uid=nil, app=:main
      credentials = MultiJson.load credentials if credentials.is_a?(String)

      klass_name = provider.to_s == 'qq_connect' ? 'QQConnect' : provider.to_s.capitalize
      klass = MonkeyKing::SNS::Strategies.const_get klass_name
      klass.new credentials, uid, app
    end

    def self.provider_with_random_token provider
      provider_from_hash provider, token: 'faketoken', secret: 'fakesecret'
    end

    def self.facebook_avatar uid
      MonkeyKing::SNS::Strategies::Facebook.picture uid, width: 150, height: 150
    end

    def self.parse_signed_request provider, request, app=:main
      secret = MonkeyKing.config.app_secret provider, app
      MonkeyKing::SNS::SignedRequestParser.new(secret).parse request
    end

  end
end
