require 'playlist'

class DashboardController < ApplicationController
  def dashboard
    @songs = Song.where(artist: '陈奕迅').limit(100)
  end

  def player
  end
end
