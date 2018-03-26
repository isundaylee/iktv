require 'songbook'
require 'encoder'
require 'playlist'

class SongsController < ApplicationController
  def download
    id = params[:id].to_i

    Songbook.start_download(id)
    redirect_back(fallback_location: root_path)
  end

  def play
    @id = params[:id].to_i
    @song = Song.find(@id)

    Encoder.start_encoding(@id)
    while !Encoder.ready_for_streaming?(@id)
    end

    redirect_to @song.play_path
  end

  def append_to_playlist
    @id = params[:id].to_i

    if !Songbook.get_status(@id)[0]
      Songbook.start_download(@id)
    end

    Playlist.append(@id)

    redirect_back(fallback_location: root_path)
  end

  private
end
