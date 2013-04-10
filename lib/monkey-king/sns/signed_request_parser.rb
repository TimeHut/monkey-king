module MonkeyKing
	module SNS
		class SignedRequestParser

			def initialize secret
				@secret = secret
			end

			def parse(value)
		    signature, encoded_payload = value.split('.')

		    decoded_hex_signature = base64_decode_url(signature)
		    decoded_payload = MultiJson.decode(base64_decode_url(encoded_payload))

		    unless decoded_payload['algorithm'] == 'HMAC-SHA256'
		      raise NotImplementedError, "unkown algorithm: #{decoded_payload['algorithm']}"
		    end

		    if valid_signature?(@secret, decoded_hex_signature, encoded_payload)
		      decoded_payload
		    end
		  end

		  private

			  def valid_signature?(secret, signature, payload, algorithm = OpenSSL::Digest::SHA256.new)
			    OpenSSL::HMAC.digest(algorithm, secret, payload) == signature
			  end
				
				def base64_decode_url(value)
			    value += '=' * (4 - value.size.modulo(4))
			    Base64.decode64(value.tr('-_', '+/'))
				end
		end
	end
end