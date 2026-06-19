Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "drills#home"

  # The drill runner: ?deck=<slug>&from=<lang>&to=<lang>
  get "play", to: "drills#play", as: :play
end
