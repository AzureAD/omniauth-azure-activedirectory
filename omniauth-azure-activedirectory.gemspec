$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'omniauth/azure_activedirectory/version'

Gem::Specification.new do |s|
  s.name            = 'omniauth-azure-activedirectory'
  s.version         = OmniAuth::AzureActiveDirectory::VERSION
  s.authors         = ['Adam Michael']
  s.email           = ['adam@ajmichael.net']
  s.summary         = 'Azure Active Directory strategy for OmniAuth'
  s.description     = 'Azure Active Directory strategy for OmniAuth'
  s.homepage        = 'https://github.com/AzureAD/omniauth-azure-activedirectory'
  s.license         = 'MIT'

  s.files           = `git ls-files`.split("\n")
  s.require_paths   = ['lib']

  s.add_runtime_dependency 'jwt', '~> 1.5'
  s.add_runtime_dependency 'omniauth', '~> 1.1'

  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'rubocop', '~> 0.32'
  s.add_development_dependency 'webmock', '~> 1.21'
end
