# encoding: utf-8
require 'singleton'
require 'monkey-king/core_ext/object'
require 'monkey-king/utils'
require 'monkey-king/sns/sns'

module MonkeyKing
  
  class Configuration
    include Singleton

    @@defaults = {}

    def provider provider, app_key, app_secret, app=:main
      @@defaults[provider.to_sym] ||= {}
      @@defaults[provider.to_sym][app.to_sym] = {:app_key => app_key, :app_secret => app_secret}
    end

    def app_key provider, app=:main
      (@@defaults[provider.to_sym] || {})[app.to_sym].try :[], :app_key
    end

    def app_secret provider, app=:main
      (@@defaults[provider.to_sym] || {})[app.to_sym].try :[], :app_secret
    end

    def test_mode=(enabled)
      @@defaults[:test_mode] = enabled
    end

    def test_mode
      @@defaults[:test_mode] || false
    end

  end

  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end

end