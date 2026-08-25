Rails.application.routes.draw do
  devise_for :users
  # user story 3 - see the adventures:
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # story 10 - reminders/notifications to check in
  resource :settings, only: %i[edit update]

  get "about" => "pages#about", as: :about

  # ownership root
  resources :uploads, only: %i[index new create show destroy] do  # story 1 - upload media, AI maps to JLPT level
    resources :saved_words, only: %i[index new create]   # story 2 - select words from the scanned content
    resources :adventures,  only: %i[new create]         # story 12 - create a new adventure
  end

  resources :uploaded_words, only: %i[destroy]           # unlink a word

  resources :saved_words, only: %i[index show edit update destroy] do
    collection { get :due }
    member     { patch :review }
  end

  # story 13 (nice to have) - import word/grammar/proverb lists
  resources :jlpt_entries, only: %i[index show] do
    collection { get :lookup }
    member     { post :save }
    collection { post :bulk_save }
  end

  resources :scenes, only: %i[index show]                # story 3 - browse storylines (same list as home)

  resources :adventures, only: %i[index show update destroy] do
  member { patch :continue }  # keep playing after hitting the word goal

  # one word's target — keyed by the word, which may not have a row yet
  patch "word_goals/:saved_word_id", to: "word_goals#update", as: :word_goal

  resources :messages, only: %i[create]                # story 7 - respond by typing
  end

  resources :messages, only: %i[show] do
    member do
      get :audio                                         # story 5 - hear the character speaking
      get :translate                                     # story 16 - translate a message to English
    end
    resource :feedback, only: %i[show]                   # story 8 - feedback on what you typed
  end
end
