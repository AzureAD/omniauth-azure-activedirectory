require 'sinatra'

# Configure Sinatra.
set :run, false
set :raise_errors, true

get '/' do
  content_type 'text/html'
  <<-HTML
    <h3>Hello there!</h3>
    <a href='/auth/azuread'>Sign in with AzureAD</a>
  HTML
end

get '/secure_endpoint' do
  redirect '/auth/azure_ad'
end

post '/auth/:provider/callback' do
  auth = request.env['omniauth.auth']
  "Your authentication looks like #{JSON.unparse(auth)}."
end

get '/auth/:provider/failure' do
  "Aw shucks, we couldn't verify your identity!"
end
