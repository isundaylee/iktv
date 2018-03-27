Rails.application.routes.draw do
  root 'dashboard#dashboard'
  get 'player', to: 'dashboard#player'

  resources :songs, only: [] do
    member do
      post 'download'
      post 'append_to_playlist'
      post 'move_to_front'
      get 'play'
    end

    collection do
      post 'shuffle'
    end
  end
end
