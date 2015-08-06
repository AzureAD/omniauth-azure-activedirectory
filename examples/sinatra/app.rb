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
