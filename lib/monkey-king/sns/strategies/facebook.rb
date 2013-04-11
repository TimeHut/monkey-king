# encoding: utf-8
module MonkeyKing
	module SNS
		module Strategies
			class Facebook
				include MonkeyKing::SNS::Strategy

				API_URL = 'https://graph.facebook.com'
				DEFAULT_FIELDS = 'id,email,name,first_name,last_name,link,username,location,verified'
				PUBLISH_PERMISSIONS = %w[create_note share_item publish_stream publish_actions]

				def publish_note message, subject
					post('me/notes', :message => message, :subject => subject)['id']
				end

				def publish_photo status, picture_path
					upload('me/photos', :source, picture_path, :message => status)['id']
				end

				def publish_link link, message=nil
					params = {:link => link}
					params[:message] = message if message

					post('me/links', params)['id']
				end

				def permissions
					raw = get('me/permissions')['data'].first
					(raw.collect {|k,v| k if v == 1}).compact
				end

				def publish_permissions
					permissions.select {|item| item.in? PUBLISH_PERMISSIONS }
				end

				def check_permission permission=nil
					permissions.include? permission.to_s
				end

				protected

					def real_user_info(params)
						normalize get('me', :fields => (params[:fields] || DEFAULT_FIELDS))
					end

					def mock_user_info(params)
						{:id => (params[:id] || '100003510141369'), :email => "acenqiu@gmail.com", :name => "Jiangyi Qiu"}
					end

				private

					def get path, params={}
						run_request nil, :get, path, params
					end

					def post path, params={}
						run_request nil, :post, path, params
					end

					def upload path, file_key, file_path, params={}
						conn = Faraday.new(:url => API_URL) do |builder|
							builder.request :multipart
				      builder.request :url_encoded
				      builder.adapter :net_http
						end
						params[file_key] = Facebook.upload_io file_path

						run_request conn, :post, path, params
					end

					def run_request conn, verb, path, params={}
						conn ||= Faraday.new(:url => API_URL)
						params.merge!(:access_token => @token)

						begin
							rep = verb == :get ? conn.get(path, params) : conn.post(path, params)
						rescue => e
							handle_faraday_error e and return
						end
						handle_faraday_response rep
					end

					#### 响应及错误处理

					def handle_faraday_response rep
						begin
							parsed = JSON.parse rep.body
						rescue => e
							raise NetworkError, e.message
						end

						if parsed['error']
							msg  = parsed['error']['message']
							type = parsed['error']['type']

							if type == 'OAuthException'
								if msg =~ /permission/i
									raise PermissionError, msg
								else
									raise InvalidTokenError, msg
								end
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

					# 将facebook返回的用户信息转换成统一格式
					def normalize raw_info
						raw_info = raw_info.with_indifferent_access
						normalized = Facebook.direct_copy raw_info, [:id, :email, :name, :first_name, :last_name, :verified]

						# 特殊处理
						if raw_info[:username]
							normalized[:nickname] = raw_info[:username]
							normalized[:urls] = {:Facebook => "http://www.facebook.com/#{raw_info[:username]}"}
						end
						normalized[:image] = "http://graph.facebook.com/#{raw_info[:id]}/picture?type=square" if raw_info[:id]
						normalized[:location] = raw_info[:location][:name] if raw_info[:location]

						# 搞定
						normalized
					end

			end
		end
	end
end