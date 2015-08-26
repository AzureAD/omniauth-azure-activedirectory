# You may want to specify these keys separately for production and test
# environments.
ENV['CLIENT_ID'] = 'YOUR CLIENT ID HERE'
ENV['CLIENT_SECRET'] = 'YOUR CLIENT SECRET HERE'
ENV['TENANT'] ='YOUR TENANT HERE'

# Load the Rails application.
require File.expand_path('../application', __FILE__)

ADAL::Logging.log_level = ADAL::Logger::VERBOSE

# Initialize the Rails application.
Rails.application.initialize!
