require 'songbook'
require 'encoder'

class SongsController < ApplicationController
  def download
    id = params[:id].to_i

    Songbook.start_download(id)
    redirect_to :root
  end

  def refresh_download_progress
    @id = params[:id].to_i
    @progress_text = "%.2f%%" % (100 * Songbook.get_status(@id)[1])
  end

  def play
    @id = params[:id].to_i
    @song = Song.find(@id)

    Encoder.start_encoding(@id)
    while !Encoder.ready_for_streaming?(@id)
    end

    redirect_to @song.play_path
  end

  private
end
