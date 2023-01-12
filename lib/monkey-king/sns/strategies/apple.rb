module MonkeyKing
  module SNS
    module Strategies
      class Apple 
        include MonkeyKing::SNS::Strategy

        APPLE_ISSUER = 'https://appleid.apple.com'
        APPLE_JWKS_URI = 'https://appleid.apple.com/auth/keys'
        JWT_RS256 = 'RS256'

        protected

          # {client_id: 'com.liveyap.TimeHut', access_token: 'aaa'}
          def real_user_info(params={})
            public_keys = get_public_keys
            if public_keys
              payload = check_against_certs(@token || params[:access_token], client_id, public_keys)

              unless payload
                raise InvalidTokenError, 'Token not verified as issued by Apple'
              end
            else
              raise InvalidTokenError, 'Unable to retrieve Apple public keys'
            end

            normalize payload.merge(name: params[:name])
          end

        private

          def normalize raw_info
            raw_info = raw_info.deep_symbolize_keys
            
            info = {
              :id       => raw_info[:sub],
              :nickname => raw_info[:name],
              :name     => raw_info[:name],
              :email    => raw_info[:email]
            }
            raw_info.merge info 
          end

          def get_public_keys
            response = HTTParty.get(APPLE_JWKS_URI)
            return false unless response.code == 200

            json_body = JSON.parse(response.body)
            json_body['keys']
          end

          def check_against_certs(token, aud, public_keys, index = 0)
            public_key = public_keys[index]
            public_key = Hash[public_key.map{ |k, v| [k.to_sym, v] }]
            puts public_key
            jwk = JWT::JWK.import(public_key)
            begin
              decoded_token = JWT.decode(token, jwk.public_key , !!public_key, {
                algorithm: JWT_RS256,
                iss: APPLE_ISSUER, verify_iss: true,
                aud: aud, verify_aud: true
                }
              )
              return decoded_token.first
            rescue => e
              if index.in?(0...public_keys.length-1)
                check_against_certs(token, aud, public_keys, index+1)
              else
                raise InvalidTokenError, e.message
              end
            end
          end

          def client_id
            MonkeyKing.config.app_key :apple, @app
          end

      end
    end
  end
end
