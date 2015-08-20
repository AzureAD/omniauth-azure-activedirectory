Rails, OmniAuth and Graph API
=============================

This is a sample MVC web application that demonstrates user authentication with OmniAuth for Azure Active Directory and RESTful calls to the AzureAD Graph API with ADAL Ruby.

## How to run this sample

To run this sample you will need
- [Ruby](https://www.ruby-lang.org/en/documentation/installation/)
- [Bundler](http://bundler.io)
- An internet connection
- An Azure subscription (a free trial is sufficient)

### Step 1 - Install ADAL from source
Note: This can and should be removed once ADAL is available on RubyGems. After that point ADAL will be installed along with the other dependencies in step 3.

```
git clone git@github.com:AzureAD/azure-activedirectory-library-for-ruby
cd azure-activedirectory-library-for-ruby
gem build adal.gemspec
gem install adal
```

### Step 2 - Install OmniAuth AzureAD from source
Note: This can and should be removed once ADAL is available on RubyGems. After that point ADAL will be installed along with the other dependencies in step 3.

```
git clone git@github.com:AzureAD/omniauth-azure-activedirectory-priv
cd omniauth-azure-activedirectory-priv
gem build omniauth-azure-activedirectory.gemspec
gem install omniauth-azure-activedirectory
```

### Step 3 - Install the sample dependencies

```
cd examples/rails-todo-list-app
bundle
```

### Step 4 - Set up the database

```
rake db:schema:load
```

Note: Depending on your host environment, you may need to install a Javascript runtime. We suggest Node.js. Installation will differ by platform.

### Step 5 - Configure the app

Open `config/environment.rb` and replace the `CLIENT_ID`, `CLIENT_SECRET` and `TENANT` with your values.

### Step 6 - Set up SSL

This step is optional to get the sample running and varies across platform and choice of webserver. Here we will present one set of instructions to accomplish this, but there are many others.

Generate a self-signed certificate.

```
openssl req -new -newkey rsa:2048 -sha1 -days 365 -nodes -x509 -keyout server.key -out server.crt
```

Get your machine/browser to trust the certificate. This varies wildly by platform.

On OSX with Safari or Chrome, double click on `server.crt` in Finder to add it to the keychain and then select 'Trust Always'.

### Step 7 - Start up Rails

This sample uses the Thin webserver to host the app on port 9292.

If you generated a certificate in Step 6

```
bundle exec thin start --port 9292 --ssl --ssl-key-file server.key --ssl-cert-file server.crt
```

If you want to skip SSL verification (shame!)

```
bundle exec thing start --port 9292 --ssl --ssl-disable-verify
```
