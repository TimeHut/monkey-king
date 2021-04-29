# encoding: utf-8
module MonkeyKing
  module SNS
    module Strategies
      class Naver
        include MonkeyKing::SNS::Strategy

        GRANT_TYPE = 'authorization_code'
        def self.max_valid_age; 3.months end

        protected

        def get_access_token_from_code
          url = "https://nid.naver.com/oauth2.0/token?grant_type=#{GRANT_TYPE}&client_id=#{app_key}&client_secret=#{app_secret}&code=#{@code}"
          puts url
          response =  Faraday.get(url)
          result =  JSON.load(response.body).deep_symbolize_keys
          if result[:error]
            raise ApiRequestError, result[:error_description]
          end
          @token = result[:access_token]
          @expires_at = result[:expires_in].to_i.seconds.from_now
        end

        def real_user_info(params)
          get_access_token_from_code
          normalize get('https://openapi.naver.com/v1/nid/me', params)
        end

        def mock_user_info(params)
          { :id => (params[:id] || '1DAA35E02713F70AEBB799F173F0FAAB'), :name => "扣扣", :location => "湖北 武汉" }
        end

        private

        def get url, params = {}
          begin
            con = Faraday.new
            res = con.get do |req|
              req.url url
              req.headers['Authorization'] = 'Bearer ' + (params[:token] || @token)
            end
            return JSON.load(res.body).deep_symbolize_keys
          rescue => e
            handle_faraday_error e
          end
        end

        def handle_faraday_error e
          if e.is_a? Faraday::Error::ClientError
            raise NetworkError, e.message
          else
            raise e
          end
        end

        # 失败
        # {
        #   resultcode: "024",
        #   message: "Authentication failed (인증 실패하였습니다.)"
        # }
        #
        def normalize raw_info
          ret = raw_info[:resultcode]
          if ret != '00'
            msg = raw_info[:message]
            raise ApiRequestError, msg
          end
          response = raw_info[:response]
          # 成功
          # {
          #   "resultcode": "00",
          #   "message": "success",
          #   "response": {
          #     "email": "openapi@naver.com",
          #     "nickname": "OpenAPI",
          #     "profile_image": "https://ssl.pstatic.net/static/pwe/address/nodata_33x33.gif",
          #     "age": "40-49",
          #     "gender": "F",
          #     "id": "32742776",
          #     "name": "오픈 API",
          #     "birthday": "10-01",
          #     "birthyear": "1900",
          #     "mobile": "010-0000-0000"
          #   }
          # }
          {
            :email    => response[:email],
            :nickname => response[:nickname],
            :name     => response[:name],
            :image    => response[:profile_image],
            :mobile   => response[:mobile],
            :gender   => response[:gender],
            :id       => response[:id],
            :age      => response[:age],
            :birthday => response[:birthday]
          }
        end

        def app_key
          MonkeyKing.config.app_key :naver, @app
        end

        def app_secret
          MonkeyKing.config.app_secret :naver, @app
        end

      end
    end
  end
end
