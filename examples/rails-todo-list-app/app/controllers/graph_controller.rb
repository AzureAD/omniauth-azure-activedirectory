class GraphController < SignedInController

  # If we have the user's ADAL credentials, then we can get an access token.
  # Otherwise we need to do the auth code flow dance.
  def index
    access_token = current_user.graph_access_token
    @user_data = user_data(access_token)
    super
  rescue ADAL::TokenRequest::UserCredentialError
    redirect_to User.authorization_request_url.to_s
  end

  # @return Hash
  def user_data(access_token)
    headers = { 'authorization' => access_token }
    me_endpt = URI('https://graph.windows.net/me?api-version=1.5')
    http = Net::HTTP.new(me_endpt.hostname, me_endpt.port)
    http.use_ssl = true
    JSON.parse(http.get(me_endpt, headers).body)
  end
end
