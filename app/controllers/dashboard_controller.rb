require 'playlist'
require 'songbook'

class DashboardController < ApplicationController
  def dashboard
    @term = params[:term]
    @is_playlist = false
    @is_downloading = false

    if @term == '__PLAYLIST__'
      @term = nil
      upcomings = Playlist.upcomings
      @songs = upcomings.map { |id| Song.find(id) }
      @is_playlist = true
    elsif @term == '__DOWNLOADING__'
      @term = nil
      upcomings = Songbook.downloading
      @songs = upcomings.map { |id| Song.find(id) }
      @is_downloading = true
    else
      if @term.present?
        byname = Song.where('name like ?', "%#{@term.strip}%").limit(100).to_a
        byartist = Song.where(artist: @term).limit(500).to_a
        @songs = byname + byartist
      else
        @songs = []
      end
    end
  end

  def player
  end
end
