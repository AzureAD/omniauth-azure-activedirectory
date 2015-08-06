# OmniAuth Azure Active Directory

OmniAuth strategy to authenticate to Azure Active Directory via OpenId Connect.

Before starting, set up a tenant and register a Web Application at [https://manage.windowsazure.com](https://manage.windowsazure.com). Note your client id and tenant for later.

# Installation

Add to your Gemfile:

```ruby
gem 'omniauth-azure-activedirectory'
```

# Usage

If you are already using OmniAuth, adding AzureAD is as simple as adding a new provider to your `OmniAuth::Builder`. The provider requires your AzureAD client id and your AzureAD tenant.

For example, in Rails you would add this in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :azure_activedirectory, ENV['AAD_CLIENT_ID'], ENV['AAD_TENANT']
  # other providers here
end
```

If you are using Sinatra or something else that requires you to configure Rack yourself, you should add this to your `config.ru`:

```ruby
use OmniAuth::Builder do
  provider :azure_activedirectory, ENV['AAD_CLIENT_ID'], ENV['AAD_TENANT']
end
```

When you want to authenticate the user, simply redirect them to `/auth/azureactivedirectory`. From there, OmniAuth will takeover. Once the user authenticates (or fails to authenticate), they will be redirected to `/auth/azureactivedirectory/callback` or `/auth/azureactivedirectory/failure`. The authentication result is available in `request.env['omniauth.auth']`.

If you are supporting multiple OmniAuth providers, you will likely have something like this in your code:

```ruby
%w(get post).each do |method|
  send(method, '/auth/:provider/callback') do
    auth = request.env['omniauth.auth']

    # Do what you see fit with your newly authenticated user.

  end
end
```

# Auth Hash

OmniAuth AzureAD tries to be consistent with the auth hash schema recommended by OmniAuth. [https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema](https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema).

Here's an example of an authentication hash available in the callback. You can access this hash as `request.env['omniauth.auth']`.

```
  :provider => "azureactivedirectory",
  :uid => "123456abcdef",
  :info => {
    :name => "John Smith",
    :email => "jsmith@contoso.net",
    :first_name => "John",
    :last_name => "Smith"
  },
  :credentials => {
    :code => "ffdsjap9fdjw893-rt2wj8r9r32jnkdsflaofdsa9"
  },
  :extra => {
    :session_state => '532fgdsgtfera32',
    :raw_info => {
      :id_token => "fjeri9wqrfe98r23.fdsaf121435rt.f42qfdsaf",
      :id_token_claims => {
        "aud" => "fdsafdsa-fdsafd-fdsa-sfdasfds",
        "iss" => "https://sts.windows.net/fdsafdsa-fdsafdsa/",
        "iat" => 53315113,
        "nbf" => 53143215,
        "exp" => 53425123,
        "ver" => "1.0",
        "tid" => "5ffdsa2f-dsafds-sda-sds",
        "oid" => "fdsafdsaafdsa",
        "upn" => "jsmith@contoso.com",
        "sub" => "123456abcdef",
        "nonce" => "fdsaf342rfdsafdsafsads"
      },
      :id_token_header => {
        "typ" => "JWT",
        "alg" => "RS256",
        "x5t" => "fdsafdsafdsafdsa4t4er32",
        "kid" => "tjiofpjd8ap9fgdsa44"
      }
    }
  }
```
