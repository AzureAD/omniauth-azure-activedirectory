class GraphController < SignedInController

  def index
    @user_data = user_data
    super
  end

  # @return Hash
  def user_data
    headers = { 'authorization' => current_user.access_token }
    me_endpt = URI('https://graph.windows.net/me?api-version=1.5')
    http = Net::HTTP.new(me_endpt.hostname, me_endpt.port)
    http.use_ssl = true
    JSON.parse(http.get(me_endpt, headers).body)
  end
end
