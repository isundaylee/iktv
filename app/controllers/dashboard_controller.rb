require 'playlist'

class DashboardController < ApplicationController
  def dashboard
    @songs = Song.where(artist: '陈奕迅').limit(100)
  end

  def player
  end

  def play_next_song
    Playlist.next()
  end
end
