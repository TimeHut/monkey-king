# encoding: utf-8
require 'singleton'
require 'monkey-king/core_ext/object'
require 'monkey-king/utils'
require 'monkey-king/sns/sns'

module MonkeyKing
  
  class Configuration
    include Singleton

    @@defaults = {}

    def provider name, app_key, app_secret
      @@defaults[name.to_sym] = {:app_key => app_key, :app_secret => app_secret}
    end

    def app_key provider
      (@@defaults[provider] || {})[:app_key]
    end

    def app_secret provider
      (@@defaults[provider] || {})[:app_secret]
    end

  end

  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end

end