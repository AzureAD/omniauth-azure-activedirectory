class User < ActiveRecord::Base
  has_many :tasks
  validates :provider, :uid, presence: true

  AUTH_CTX = ADAL::AuthenticationContext.new(
    'login.windows.net', ENV['TENANT'])
  CLIENT_CRED = ADAL::ClientCredential.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'])
  GRAPH_RESOURCE = 'https://graph.windows.net'

  def self.from_omniauth(auth_hash)
    user = User.where(provider: auth_hash[:provider],
                      uid: auth_hash[:uid]).first_or_create
    user.name = auth_hash[:info]['name']
    user.email = auth_hash[:info]['email']

    # Note that this is the first part that is AAD specific.
    if auth_hash[:credentials]['code']
      user.redeem_code(
        auth_hash[:credentials]['code'],
        'http://localhost:9292/auth/azureactivedirectory/callback')
    end
    user.save!
    user
  end

  def graph_access_token
    AUTH_CTX.acquire_token_for_user(GRAPH_RESOURCE, CLIENT_CRED, adal_user_identifier).access_token
  end

  def redeem_code(auth_code, reply_url)
    adal_user = AUTH_CTX.acquire_token_with_authorization_code(
                  auth_code,
                  reply_url,
                  CLIENT_CRED,
                  GRAPH_RESOURCE
                ).user_info
    self.adal_unique_id = adal_user.unique_id
    self.adal_displayable_id = adal_user.displayable_id
    self.save!
  end

  def self.authorization_request_url
    AUTH_CTX.authorization_request_url(
      GRAPH_RESOURCE,
      ENV['CLIENT_ID'], 
      'http://localhost:9292/authorize')
  end

  private

  def adal_user_identifier
    if adal_displayable_id
      ADAL::UserIdentifier.new(adal_displayable_id, :DISPLAYABLE_ID)
    else
      ADAL::UserIdentifier.new(adal_unique_id, :UNIQUE_ID)
    end
  end
end
