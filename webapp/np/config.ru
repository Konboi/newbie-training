$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require ::File.expand_path('../app.rb', __FILE__)

require 'rack/csrf'
use Rack::Session::Cookie, secret: 'Z4NzcPPaHspO9C5OaPBjs7T7dBuipx'
use Rack::Csrf, raise: true, field: 'csrf_token'

run Sinatra::Application
