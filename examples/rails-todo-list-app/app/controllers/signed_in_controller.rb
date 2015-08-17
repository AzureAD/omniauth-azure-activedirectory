# Any controllers that require users to sign in should extend this class.
class SignedInController < ApplicationController
  before_filter :require_sign_in
  skip_before_filter :verify_authenticity_token

  def index
    @current_user = current_user
    render :index
  end

  def require_sign_in
    redirect_to root_path if current_user.nil?
  end

  def add_auth
    current_user.redeem_code(
      params['code'],
      'http://localhost:9292/authorize')
    redirect_to graph_index_path
  end

  def current_user
    User.find_by_id(session['user_id'])
  end
end
