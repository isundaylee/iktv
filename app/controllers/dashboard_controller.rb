require 'playlist'

class DashboardController < ApplicationController
  def dashboard
    @songs = Song.where(artist: '陈奕迅').limit(100)
  end

  def player
  end

  def play_next_song
    @id = Playlist.pop_next()

    if @id.nil?
      @link = nil
    else
      @song = Song.find(@id)

      Encoder.start_encoding(@id)
      while !Encoder.ready_for_streaming?(@id)
      end

      @link = @song.play_path
    end
  end
end
