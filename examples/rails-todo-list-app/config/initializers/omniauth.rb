Rails.application.config.middleware.use OmniAuth::Builder do
  provider :azure_activedirectory, ENV['CLIENT_ID'], ENV['TENANT']
  provider :twitter, ENV['TWITTER_ID'], ENV['TWITTER_SECRET']
end
