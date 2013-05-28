require 'test/unit'
require 'rack/test'
require 'rack'
require 'json'

$:.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
Dir[File.dirname(__FILE__) + '/test_helpers/**/*.rb'].each { |file| require file}

require 'raw2swagger'
include Raw2Swagger

