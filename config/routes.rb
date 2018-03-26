Rails.application.routes.draw do
  root 'dashboard#dashboard'
  get 'player', to: 'dashboard#player'
  post 'play_next_song', to: 'dashboard#play_next_song'

  resources :songs, only: [] do
    member do
      post 'download'
      post 'refresh_download_progress'
      post 'append_to_playlist'
      get 'play'
    end
  end
end
