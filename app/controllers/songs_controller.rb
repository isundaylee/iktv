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
    id = params[:id].to_i
    song = Song.find(id)

    lines = File.read(Encoder.encoded_video_path(id)).lines
    0.upto(lines.count - 1) do |i|
      if lines[i] =~ /^.+\.ts$/
        lines[i] = song.encoded_fragments_path + "/" + lines[i]
      end
    end

    lines.insert(1, "#EXT-X-START:TIME-OFFSET=0\n")

    render inline: lines.join, content_type: 'application/vnd.apple.mpegurl'
  end

  def append_to_playlist
    @id = params[:id].to_i

    if !Songbook.get_status(@id)[0]
      Songbook.start_download(@id)
    end

    Playlist.append(@id)

    redirect_back(fallback_location: root_path)
  end

  def shuffle
    Playlist.shuffle()

    redirect_back(fallback_location: root_path)
  end

  def move_to_front
    id = params[:id].to_i

    Playlist.move_to_front(id)

    redirect_back(fallback_location: root_path)
  end

  private
end
