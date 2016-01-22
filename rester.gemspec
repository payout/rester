$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rester/version"

Gem::Specification.new do |s|
  s.name        = 'rester'
  s.version     = Rester::VERSION
  s.homepage    = "http://github.com/payout/rester"
  s.license     = 'BSD'
  s.summary     = "A framework for creating simple RESTful interfaces between services."
  s.description = s.summary
  s.authors     = ["Robert Honer", "Kayvon Ghaffari"]
  s.email       = ['robert@payout.com', 'kayvon@payout.com']
  s.files       = Dir['lib/**/*.rb'] + Dir['lib/tasks/**/*.rake']

  s.add_dependency 'rack', '~> 1.5', '>= 1.5.2'
  s.add_dependency 'activesupport'
  s.add_dependency 'thread_safe'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rails', '~> 4.0.0'
  s.add_development_dependency 'bundler-audit'
  s.add_development_dependency 'newrelic_rpm'
end
