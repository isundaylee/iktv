Rails.application.routes.draw do
  root 'dashboard#dashboard'

  resources :songs, only: [] do
    member do
      post 'download'
      post 'refresh_download_progress'
    end
  end
end
