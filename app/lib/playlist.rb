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

      Encoder.start_encoding(id)
      while !Encoder.ready_for_streaming?(id)
      end

      link = song.play_path
      @@playing = true
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
