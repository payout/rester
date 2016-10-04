ENV['RACK_ENV'] ||= 'development'

# Load the appropriate environment file.
require File.expand_path("../environments/#{ENV['RACK_ENV']}", __FILE__)

# Load the application
require File.expand_path('../application', __FILE__)

# Ensure that required values are defined.
REQUIRED_ENV = [].freeze
REQUIRED_ENV.each { |env| raise "#{env} is a required ENV" unless ENV[env] }

# Load the initializers
Dir[File.expand_path('../initializers/**', __FILE__)].sort.each { |f| require f }