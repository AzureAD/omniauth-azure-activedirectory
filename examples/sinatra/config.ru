#-------------------------------------------------------------------------------
# # Copyright (c) Microsoft Open Technologies, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A
# PARTICULAR PURPOSE, MERCHANTABILITY OR NON-INFRINGEMENT.
#
# See the Apache License, Version 2.0 for the specific language
# governing permissions and limitations under the License.
#-------------------------------------------------------------------------------

require 'dotenv'
require 'omniauth'
require 'omniauth-amazon'
require 'omniauth-azure-activedirectory'
require 'omniauth-github'
require 'omniauth-google-oauth2'

# Load API keys from .env
Dotenv.load

require_relative './app.rb'

# You must provide a session to use OmniAuth.
use Rack::Session::Cookie, secret: 'top secret'

use OmniAuth::Builder do
  provider :amazon, ENV['AMAZON_KEY'], ENV['AMAZON_SECRET']
  provider :azure_activedirectory, ENV['AAD_KEY'], ENV['AAD_TENANT']
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
  provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET']
end

run Sinatra::Application
