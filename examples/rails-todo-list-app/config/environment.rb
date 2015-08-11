# You may want to specify these keys separately for production and test
# environments.
ENV['CLIENT_ID'] = 'd0644584-61de-4bca-98ab-e75af0ff5528'
ENV['CLIENT_SECRET'] = 'La55NMCC2ouDu3grNO5/wlCjE7qmAV0YnJFFIOYVU6U='
ENV['TENANT'] ='adamajmichael.onmicrosoft.com'

# Load the Rails application.
require File.expand_path('../application', __FILE__)

ADAL::Logging.log_level = ADAL::Logger::VERBOSE

# Initialize the Rails application.
Rails.application.initialize!
