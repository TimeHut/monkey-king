$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "monkey-king/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "monkey-king"
  s.version     = MonkeyKing::VERSION
  s.authors     = ["Acen"]
  s.email       = ["acenqiu@gmail.com"]
  s.homepage    = "https://github.com/TimeHut/monkey-king"
  s.summary     = "MonkeyKing is a set of tools used in TimeHut."
  s.description = "MonkeyKing is a set of tools used in TimeHut."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'faraday'
  s.add_dependency 'multi_json', '>= 1.0'
  s.add_dependency 'oauth2', '>= 0.5'
  s.add_dependency 'chinese_pinyin', '>= 0.6.0'
end
