Rails.application.config.middleware.use OmniAuth::Builder do
  provider :azure_activedirectory, ENV['CLIENT_ID'], ENV['TENANT']
end
