# encoding: utf-8
module MonkeyKing
	module SNS
		module Strategies
			class Weibo
				include MonkeyKing::SNS::Strategy

				API_URL  = 'https://api.weibo.com/2/'
				BASE_URL = 'http://weibo.com'

				def self.max_valid_age; 15.years end

				def publish_status status
					result = post 'statuses/update.json', :status => status
					result['idstr']
				end

				def publish_photo status, picture_path
					result = upload 'statuses/upload.json', :pic, picture_path, :status => status
					result['idstr']
				end

				def get_uid
					get('account/get_uid.json')['uid']
				end

				def check_permission permission=nil
					get_uid and return true # 只要能获取当前用户id即拥有权限
				end

				protected

					def real_user_info(params)
						normalize get('users/show.json', :uid => (params[:id] || get_uid))
					end

					def mock_user_info(params)
						{:id => (params[:id] || '1629430940'), :name=>"我才是Acen", :location=>"湖北 武汉"}
					end

				private

					def get path, params={}
						begin
							rep = get_access_token.get path, :params => params
							rep.parsed
						rescue => e
							handle_oauth_error e
						end
					end

					def post path, params={}
						begin
							rep = get_access_token.post path, :body => params
							rep.parsed
						rescue => e
							handle_oauth_error e
						end
					end

					def upload path, file_key, file_path, params={}
						begin
							params[file_key] = Weibo.upload_io file_path
							rep = get_access_token(true).post path, :body => params
							rep.parsed
						rescue => e
							handle_oauth_error e
						end
					end

					def handle_oauth_error e
						if e.is_a? Faraday::Error::ClientError
							raise NetworkError, e.message
						elsif e.is_a?(OAuth2::Error) && e.response.parsed.is_a?(Hash)
							code = e.response.parsed['error_code']
							if code.in?([10006, 10013]) || code.in?(21301..21502)
								raise InvalidTokenError, e.message
							elsif code.in? [20016, 20017, 20019, 20038]
								raise RepeatContentError, e.message
							else
								raise ApiRequestError, e.message
							end
						else
							raise e
						end
					end

					def get_access_token with_multipart=false
						client = with_multipart ? client_with_multipart : default_client
						OAuth2::AccessToken.new(client, @token, :header_format => 'OAuth2 %s')
					end

					def default_client
						OAuth2::Client.new app_key, app_secret, :site => API_URL
					end

					def client_with_multipart
						OAuth2::Client.new app_key, app_secret, :site => API_URL do |builder|
							builder.request :multipart
				      builder.request :url_encoded
				      builder.adapter :net_http
						end
					end

					# 将weibo返回的用户信息转换成统一格式
					def normalize raw_info
						raw_info = raw_info.with_indifferent_access
						normalized = Weibo.direct_copy raw_info, [:name, :location, :description]

						# 特殊处理
						normalized[:id] = raw_info[:idstr]
						normalized[:nickname] = raw_info[:screen_name] if raw_info[:screen_name]
						normalized[:image] = raw_info[:profile_image_url] if raw_info[:profile_image_url]
						normalized[:urls] = {
							'Blog' => raw_info[:url],
							'Weibo' => raw_info[:domain].present? ? "#{BASE_URL}/#{raw_info[:domain]}" : "#{BASE_URL}/u/#{raw_info[:id]}"
						}

						normalized
					end

					def app_key
						MonkeyKing.config.app_key :weibo
					end

					def app_secret
						MonkeyKing.config.app_secret :weibo
					end

			end
		end
	end
end