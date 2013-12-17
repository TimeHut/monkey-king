require 'chinese_pinyin'

module MonkeyKing
  class Utils
    def self.escape_domain(domain)
      white_list = ('a'..'z').to_a + ('A'..'Z').to_a + ('1'..'9').to_a + ['-']

      escaped = ''
      origin = Pinyin.t(domain.to_s)
      origin.length.times do |i|
        char = origin[i]
        escaped += char if white_list.include?(char)
      end

      escaped
    end
  end
end