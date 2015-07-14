require 'omniauth-azure-ad'
require './app.rb'

# You must provide a session to use OmniAuth.
use Rack::Session::Cookie, secret: 'top secret'

use OmniAuth::Strategies::AzureAD,
  client_id: 'd0644584-61de-4bca-98ab-e75af0ff5528',
  resource: 'https://graph.windows.net'

run Sinatra::Application
