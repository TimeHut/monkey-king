# encoding: utf-8
module MonkeyKing
  module SNS
    module Strategies
      class Twitter
        include MonkeyKing::SNS::Strategy

        def self.need_token_secret?; true end
        def self.max_valid_age; 100.years end

        def publish_status status
          begin
            client.update(status).id.to_s
          rescue => e
            handle_twitter_error e
          end
        end

        def publish_photo status, picture_path
          begin
            client.update_with_media(status, File.new(picture_path)).id.to_s
          rescue => e
            handle_twitter_error e
          end
        end

        def check_permission permission=nil
          client.verify_credentials :include_entities => false, :skip_status => true
          true
        end

        protected

          def real_user_info(params)
            begin
              normalize client.user(:include_entities => false, :skip_status => true)
            rescue => e
              handle_twitter_error e
            end
          end

          def mock_user_info(params)
            {:id => (params[:id] || '106463496'), :name=>"Acen", :location=>""}
          end

        private

          def handle_twitter_error e
            if e.is_one_of? [::Twitter::Error::AlreadyFavorited, ::Twitter::Error::AlreadyRetweeted]
              raise RepeatContentError, e.message
            elsif e.is_a?(::Twitter::Error::Unauthorized)
              raise InvalidTokenError, e.message
            elsif e.is_one_of? [::Twitter::Error::ServerError, ::Twitter::Error::ClientError]
              raise NetworkError, e.message
            else
              raise ApiRequestError, e.message
            end
          end

          def client
            ::Twitter::Client.new(
              :consumer_key => MonkeyKing.config.app_key(:twitter),
              :consumer_secret => MonkeyKing.config.app_secret(:twitter),
              :oauth_token => @token,
              :oauth_token_secret => @token_secret
            )
          end

          def normalize user
            {
              :id => user.id.to_s,
              :nickname => user.screen_name,
              :name => user.name,
              :image => user.profile_image_url,
              :location => user.location,
              :description => user.description,
              :urls => {
                'Website' => user.url,
                'Twitter' => 'http://twitter.com/' + user.screen_name
              }
            }
          end
      end
    end
  end
end