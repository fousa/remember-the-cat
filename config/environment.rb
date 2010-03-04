RAILS_GEM_VERSION = '1.2.3' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
end

CONFIG = YAML.load_file("#{RAILS_ROOT}/config/config.yml")[RAILS_ENV]