# Any controllers that require users to sign in should extend this class.
class SignedInController < ApplicationController
  before_filter :require_sign_in

  def index
    @current_user = current_user
    render :index
  end

  def require_sign_in
    redirect_to root_path if current_user.nil?
  end

  def current_user
    User.find_by_id(session['user_id'])
  end
end
