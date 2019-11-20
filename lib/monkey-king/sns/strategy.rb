# encoding: utf-8
require 'faraday'
require 'oauth2'

module MonkeyKing
  module SNS
    class CommonError < StandardError; end

    class NetworkError < CommonError; end
    class InvalidCodeError < CommonError; end
    class InvalidTokenError < CommonError; end
    class RepeatContentError < CommonError; end
    class PermissionError < CommonError; end
    class ApiRequestError < CommonError; end

    module Strategy
      def self.included(receiver)
        receiver.extend ClassMethods
      end

      module ClassMethods
        
        def need_token_secret?; false end
        def max_valid_age; 2.months end

        def direct_copy from, keys=[]
          to = {}
          keys.each { |key| to[key] = from[key] if from[key] }
          to
        end

        def upload_io path
          mime = case File.extname(path)
          when '.jpg'  then 'image/jpg'
          when '.jpeg' then 'image/jpeg'
          when '.png'  then 'image/png'
          when '.gif'  then 'image/gif'
          else
            'image/jpg'
          end

          Faraday::UploadIO.new path, mime
        end

      end

      attr_reader :app, :code, :token, :token_secret, :expires_at, :uid
      
      def initialize credentials, uid=nil, app=:main
        credentials = credentials || {}

        @app   = app
        @code  = credentials[:code]
        @token = credentials[:access_token] || credentials[:token]
        @token_secret = credentials[:token_secret] || credentials[:secret] if self.class.need_token_secret?

        @expires_at = Time.at credentials[:expires_at].to_i
        if @expires_at < Time.now || @expires_at > self.class.max_valid_age.from_now
          @expires_at = self.class.max_valid_age.from_now
        end

        @uid = uid

        if @token.blank? || (self.class.need_token_secret? && @token_secret.blank?)
          if @code
            get_access_token_from_code
          else
            raise InvalidTokenError
          end
        end
      end

      def credentials_hash
        credentials = {:token => @token}
        credentials[:secret] = @token_secret if self.class.need_token_secret?
        if self.class.max_valid_age < 50.years
          credentials.merge! :expires_at => @expires_at.to_i, :expires => true
        end

        credentials
      end

      def uid
        @uid || user_info[:id]
      end

      # 取用户信息，默认在有缓存时读取缓存的内容
      # @param params  [Hash]
      # @param options [Hash] :force_reload, :test_mode
      def user_info params={}, options={}
        params  ||= {}
        options ||= {}
        @user_info = nil if options[:force_reload]
        unless @user_info
          @user_info = MonkeyKing.config.test_mode ? mock_user_info(params) : real_user_info(params)
        end

        @user_info
      end

      # 检测是否有指定权限，如果token无效，触发InvalidTokenError,否则返回true/false
      def check_permission permission=nil
        raise NotImplementedError
      end

      def get_access_token_from_code
        raise InvalidTokenError
      end

      protected

        def real_user_info(params); {} end
        
        def mock_user_info(params); {} end

    end
  end
end