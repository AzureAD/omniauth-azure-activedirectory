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
git clone git@github.com/AzureAD/azure-activedirectory-library-for-ruby
cd azure-activedirectory-library-for-ruby
gem build adal.gemspec
gem install adal
```

### Step 2 - Install OmniAuth AzureAD from source
Note: This can and should be removed once ADAL is available on RubyGems. After that point ADAL will be installed along with the other dependencies in step 3.

```
git clone git@github.com/AzureAD/omniauth-azure-activedirectory-library
cd omniauth-azure-activedirectory-library
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

### Step 5 - Configure the app

Open `config/environment.rb` and replace the `CLIENT_ID`, `CLIENT_SECRET` and `TENANT` with your values.

### Step 6 - Start up Rails

```
rails server
```
