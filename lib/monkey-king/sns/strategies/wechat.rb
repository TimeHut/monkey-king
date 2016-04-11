# encoding: utf-8
module MonkeyKing
  module SNS
    module Strategies
      class Wechat
        include MonkeyKing::SNS::Strategy

        def self.max_valid_age; 30.days end

        protected

          def real_user_info(params)
            normalize get('https://api.weixin.qq.com/sns/userinfo', :openid => params[:id])
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

          # callback( {"client_id":"YOUR_APPID","openid":"YOUR_OPENID"} );
          # callback( {"error":100016,"error_description":"access token check failed"} );
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

      end
    end
  end
end