require 'rester'
require 'rails'

module Rester
  class Railtie < Rails::Railtie
    railtie_name :rester

    rake_tasks do
      Rester.load_tasks
    end
  end
end
