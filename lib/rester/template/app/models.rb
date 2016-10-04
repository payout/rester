##
# Lazy load the models
Dir[File.expand_path('../models/**.rb', __FILE__)].each { |f|
  class_name = File.basename(f)[0..-4].split('_').map(&:capitalize).join.to_sym
  autoload(class_name, f)
}
