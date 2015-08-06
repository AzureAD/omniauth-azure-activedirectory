require 'dotenv'
require 'omniauth'
require 'omniauth-amazon'
require 'omniauth-azure-ad'
require 'omniauth-github'
require 'omniauth-google-oauth2'

# Load API keys from .env
Dotenv.load

require_relative './app.rb'

# You must provide a session to use OmniAuth.
use Rack::Session::Cookie, secret: 'top secret'

use OmniAuth::Builder do
  provider :amazon, ENV['AMAZON_KEY'], ENV['AMAZON_SECRET']
  provider :azuread, ENV['AAD_KEY'], ENV['AAD_TENANT']
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
  provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET']
end

run Sinatra::Application
