Rails.application.routes.draw do
  root to: 'home#index'

  resource :session, only: [:destroy]
  resources :profile, only: [:index]
  resources :tasks, only: [:index, :update, :create, :destroy, :post]
  resources :tasks do
    collection do
      post 'cloud_save', action: :cloud_save
    end
  end

  # This is where we send people to authenticate with OmniAuth.
  get '/auth/azureactivedirectory', as: :sign_in

  # This is where we are redirected if OmniAuth successfully authenicates
  # the user.
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]

  # This is where we are redirected if we acquire authorization separately from
  # OmniAuth.
  match '/authorize', to: 'signed_in#add_auth', via: [:get, :post]

  # This is where we are redirected if OmniAuth fails to authenticate the user.
  # user
  match '/auth/:provider/failure', to: redirect('/'), via: [:get, :post]
end
