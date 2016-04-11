# encoding: utf-8
module MonkeyKing
  module SNS
    module Strategies
      class Wechat
        include MonkeyKing::SNS::Strategy

        def self.max_valid_age; 30.days end

        protected

          def get_access_token_from_code
            params = {appid: app_key, secret: app_secret, code: @code, grant_type: 'authorization_code'}
            result = get 'https://api.weixin.qq.com/sns/oauth2/access_token', params

            @uid        = result['openid']
            @token      = result['access_token']
            @expires_at = result['expires_in'].to_i.seconds.from_now
          end

          def real_user_info(params)
            normalize get('https://api.weixin.qq.com/sns/userinfo', :openid => (params[:id] || @uid))
          end

          def mock_user_info(params)
            {:id => (params[:id] || 'oPNOUs54edXqanoZI6bXaMzTfC3M'), :name=>"H3c", :location=>"Hubei Wuhan"}
          end

        private

          def get url, params={}
            params.merge!(:access_token => (params[:access_token] || @token))

            begin
              handle_faraday_response Faraday.get(url, params)
            rescue => e
              handle_faraday_error e
            end
          end

          def handle_faraday_response rep
            begin
              parsed = MultiJson.load rep.body
            rescue => e
              raise NetworkError, e.message
            end

            ret = parsed['errcode'].to_i
            if ret != 0
              msg = parsed['errmsg']

              if ret.in? 42001..42003
                raise InvalidTokenError, msg
              elsif ret == 40029
                raise InvalidCodeError, msg
              else
                raise ApiRequestError, msg
              end
            else
              parsed
            end
          end

          def handle_faraday_error e
            if e.is_a? Faraday::Error::ClientError
              raise NetworkError, e.message
            else
              raise e
            end
          end

          def normalize raw_info
            raw_info = raw_info.with_indifferent_access
            
            {
              :id       => raw_info[:openid],
              :union_id => raw_info[:unionid],
              :nickname => raw_info[:nickname],
              :name     => raw_info[:nickname],
              :image    => raw_info[:headimgurl]
            }
          end

          def app_key
            MonkeyKing.config.app_key :wechat, @app
          end

          def app_secret
            MonkeyKing.config.app_secret :wechat, @app
          end

      end
    end
  end
end