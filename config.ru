require 'bundler'
Bundler.require

require './app'

App.run! { |server| }
