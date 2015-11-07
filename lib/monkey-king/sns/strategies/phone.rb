module MonkeyKing
  module SNS
    module Strategies
      class Phone
        include MonkeyKing::SNS::Strategy

        def self.max_valid_age; 100.years end

        protected
          def real_user_info(params)
            uid = [params[:phone_code], params[:phone]].join('_')
            {
              :uid   => uid,
              :name  => uid,
              :image => nil
            }
          end

          def mock_user_info(params)
            {:id => (params[:id] || '1DAA35E02713F70AEBB799F173F0FAAB'), :name=>"扣扣", :location=>"湖北 武汉"}
          end
      end
    end
  end
end
