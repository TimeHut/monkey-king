# encoding: utf-8
module MonkeyKing
  module SNS
    module Strategies
      class QQConnect
        include MonkeyKing::SNS::Strategy

        def self.max_valid_age; 3.months end

        def get_uid
          get('https://graph.qq.com/oauth2.0/me')['openid']
        end

        def check_permission permission=nil
          get_uid and return true # 只要能获取当前用户id即拥有权限
        end

        protected

          def real_user_info(params)
            uid = params[:id] || get_uid
            params = {oauth_consumer_key: app_key, openid: uid}

            normalize get('https://graph.qq.com/user/get_user_info', params).merge(id: uid)
          end

          def mock_user_info(params)
            {:id => (params[:id] || '1DAA35E02713F70AEBB799F173F0FAAB'), :name=>"扣扣", :location=>"湖北 武汉"}
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

          # callback( {"client_id":"YOUR_APPID","openid":"YOUR_OPENID"} );
          # callback( {"error":100016,"error_description":"access token check failed"} );
          def handle_faraday_response rep
            match = rep.body.match(/callback\((?<json>.*?)\);/)
            json_string = match ? match[:json].try(:strip) : rep.body

            begin
              parsed = MultiJson.load json_string
            rescue => e
              raise NetworkError, e.message
            end

            ret = (parsed['error'] || parsed['ret']).to_i
            if ret != 0
              msg = parsed['error_description'] || parsed['msg']

              if ret.in? 100013..100016
                raise InvalidTokenError, msg
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
            image_key = raw_info[:figureurl_qq_2].present? ? :figureurl_qq_2 : :figureurl_1
            
            {
              :id       => raw_info[:id],
              :nickname => raw_info[:nickname],
              :name     => raw_info[:nickname],
              :image    => raw_info[image_key]
            }
          end

          def app_key
            MonkeyKing.config.app_key :qq_connect
          end

      end
    end
  end
end