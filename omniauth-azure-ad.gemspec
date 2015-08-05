$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'omniauth/azure_ad/version'

Gem::Specification.new do |s|
  s.name            = 'omniauth-azure-ad'
  s.version         = OmniAuth::AzureAD::VERSION
  s.authors         = ['Adam Michael']
  s.email           = ['adam@ajmichael.net']
  s.summary         = 'AzureAD strategy for OmniAuth'
  s.description     = 'AzureAD strategy for OmniAuth'
  s.homepage        = 'https://github.com/aj-michael/omniauth-azure-ad'
  s.license         = 'MIT'

  s.files           = `git ls-files`.split("\n")
  s.require_paths   = ['lib']

  s.add_runtime_dependency 'jwt', '~> 1.5'
  s.add_runtime_dependency 'omniauth', '~> 1.1'

  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'rake', '~> 10.4'
end
