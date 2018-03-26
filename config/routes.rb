Rails.application.routes.draw do
  root 'dashboard#dashboard'
  get 'player', to: 'dashboard#player'

  resources :songs, only: [] do
    member do
      post 'download'
      post 'refresh_download_progress'
      post 'append_to_playlist'
      get 'play'
    end
  end
end
