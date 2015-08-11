class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def new
    redirect_to '/auth/azureactivedirectory'
  end

  def create
    user = User.find_by_provider_and_uid(auth_hash['provider'],
                                         auth_hash['uid'])
    user ||= User.from_omniauth(auth_hash)
    session['user_id'] = user.id
    redirect_to tasks_path
  end

  def destroy
    reset_session
    redirect_to root_url
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
