require 'restercom'
require 'rails'

module Restercom
  class Railtie < Rails::Railtie
    railtie_name :restercom

    rake_tasks do
      Restercom.load_tasks
    end
  end
end
