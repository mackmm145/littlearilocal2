Rails.application.routes.draw do
  root :to => 'pages#home'
  get '/posi1', :to => 'pages#posi1'
  get '/posi2', :to => 'pages#posi2'
  get '/terminal1', :to => 'pages#terminal1'
  get '/terminal2', :to => 'pages#terminal2'
  get '/testpage', :to => 'pages#testpage'

  get '/customer_display', :to => 'pages#customer_display'

  mount ActionCable.server => '/cable'

  get '/lunchmenu', :to => 'pages#lunch'
end
