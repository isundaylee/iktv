Rails.application.routes.draw do
  root 'dashboard#dashboard'
  get 'player', to: 'dashboard#player'

  resources :songs, only: [] do
    member do
      post 'download'
      post 'append_to_playlist'
      get 'play'
    end
  end
end
