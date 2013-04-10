# encoding: utf-8
module MonkeyKing
	module SNS
		class CommonError < StandardError; end

		class NetworkError < CommonError; end
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
			
			def initialize credentials
				credentials = (credentials || {}).with_indifferent_access

				@token = credentials[:access_token] || credentials[:token]
				@token_secret = credentials[:token_secret] || credentials[:secret] if self.class.need_token_secret?

				@expires_at = Time.at credentials[:expires_at].to_i
				if @expires_at < Time.now || @expires_at > self.class.max_valid_age.from_now
					@expires_at = self.class.max_valid_age.from_now
				end

				if @token.blank? || (self.class.need_token_secret? && @token_secret.blank?)
					raise InvalidTokenError
				end
			end

			def uid
				user_info[:id]
			end

			# 取用户信息，默认在有缓存时读取缓存的内容
			# @param params  [Hash]
			# @param options [Hash] :force_reload, :test_mode
			def user_info params={}, options={}
				params  ||= {}
				options ||= {}
				@user_info = nil if options[:force_reload]
				unless @user_info
					@user_info = options[:test_mode] ? mock_user_info(params) : real_user_info(params)
				end

				@user_info
			end

			def publish_status status
				raise NotImplementedError
			end

			def publish_photo status, picture_path
				raise NotImplementedError
			end

			protected

				def real_user_info(params); {} end
				
				def mock_user_info(params); {} end

		end
	end
end