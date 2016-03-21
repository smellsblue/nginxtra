App::Application.routes.draw do
  root to: "tests#index"

  resources :restart_test, only: [:index] do
    collection do
      post :restart_nginxtra
      get :long_request
    end
  end
end
