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
    adal_user = AUTH_CTX.acquire_token_with_authorization_code(
                  auth_hash[:credentials]['code'],
                  'http://localhost:9292/auth/azureactivedirectory/callback',
                  CLIENT_CRED,
                  GRAPH_RESOURCE
                ).user_info
    user.adal_unique_id = adal_user.unique_id
    user.adal_displayable_id = adal_user.displayable_id
    user.save!
    user
  end

  def access_token
    AUTH_CTX.acquire_token_for_user(GRAPH_RESOURCE, CLIENT_CRED, user_identifier).access_token
  end

  private

  def user_identifier
    if adal_displayable_id
      ADAL::UserIdentifier.new(adal_displayable_id, :DISPLAYABLE_ID)
    else
      ADAL::UserIdentifier.new(adal_unique_id, :UNIQUE_ID)
    end
  end
end
