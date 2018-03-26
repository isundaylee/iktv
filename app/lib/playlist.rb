require 'songbook'

class Playlist
  @@list = []
  @@playing = false

  def self.upcomings
    return @@list
  end

  def self.pop_next()
    @@list.each do |song|
      if Songbook.get_status(song)[0]
        @@list.delete(song)
        return song
      end
    end

    return nil
  end

  def self.next()
    id = pop_next()

    if id.nil?
      link = nil
      @@playing = false
    else
      song = Song.find(id)

      Encoder.stop_all()
      if Encoder.start_encoding(id)
        # We actually started an encoding
        # Send a blank screen before we're ready to show the actual song
        ActionCable.server.broadcast "playlist_notifications_channel",
          type: 'play',
          url: nil
      end

      if Encoder.wait_until_ready(id)
        link = song.play_path
        @@playing = true
      else
        link = nil
      end
    end

    ActionCable.server.broadcast "playlist_notifications_channel",
      type: 'play',
      url: link
  end

  def self.append(id)
    @@list << id

    if !@@playing
      self.next()
    end
  end

  def self.get_index_of_song(id)
    @@list.index(id)
  end
end
