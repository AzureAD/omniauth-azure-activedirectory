#-------------------------------------------------------------------------------
# Copyright (c) 2015 Micorosft Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
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
  send(method, '/auth/failure') do
    "Aw shucks, we couldn't verify your identity!"
  end
end
