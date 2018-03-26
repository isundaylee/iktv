require 'songbook'

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

    original = FFMPEG::Movie.new(Songbook.song_path(@id).to_s)
    output_path = Songbook.frags_path(@id)

    Thread.new do
      original.transcode(output_path.to_s,
        %w(-b 1000k -vcodec libx264 -hls_time 1 -hls_list_size 0 -f hls -g 24))
    end

    while !File.exists?(Songbook.second_part_path(@id))
    end

    redirect_to @song.play_path
  end

  private
end
