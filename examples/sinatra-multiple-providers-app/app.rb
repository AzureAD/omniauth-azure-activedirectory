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

require 'sinatra'

# Configure Sinatra.
set :run, false
set :raise_errors, true

get '/' do
  content_type 'text/html'
  <<-HTML
    <h3>Hello there!</h3>
    <a href='/auth/amazon'>Sign in with Amazon</a>
    <a href='/auth/azureactivedirectory'>Sign in with AzureAD</a>
    <a href='/auth/github'>Sign in with Github</a>
    <a href='/auth/google_oauth2'>Sign in with Google</a>
  HTML
end

%w(get post).each do |method|
  send(method, '/auth/:provider/callback') do
    auth = request.env['omniauth.auth']
    "Your authentication looks like #{JSON.unparse(auth)}."
  end
end

%w(get post).each do |method|
  send(method, '/auth/:provider/failure') do
    "Aw shucks, we couldn't verify your identity!"
  end
end
