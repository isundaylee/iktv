require 'thread'
require 'songbook'

class Playlist
  @@list = []
  @@playing = false
  @@mu = Mutex.new

  def self.upcomings
    return @@mu.synchronize do
      @@list
    end
  end

  def self.pop_next()
    return @@mu.synchronize do
      result = nil
      @@list.each do |song|
        if Songbook.get_status(song)[0]
          @@list.delete(song)
          result = song
          break
        end
      end

      result
    end
  end

  def self.next()
    id = pop_next()

    if id.nil?
      link = nil

      @@mu.synchronize do
        @@playing = false
      end
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

        @@mu.synchronize do
          @@playing = true
        end
      else
        link = nil
      end
    end

    ActionCable.server.broadcast "playlist_notifications_channel",
      type: 'play',
      url: link
  end

  def self.append(id)
    should_play_next = @@mu.synchronize do
      @@list << id
      !@@playing
    end

    if should_play_next
      self.next()
    end
  end

  def self.shuffle
    @@mu.synchronize do
      @@list.shuffle!
    end
  end

  def self.move_to_front(id)
    @@mu.synchronize do
      if !@@list.include?(id)
        false
      else
        @@list.delete(id)
        @@list.unshift(id)
      end
    end
  end

  def self.get_index_of_song(id)
    result = @@mu.synchronize do
      @@list.index(id)
    end

    result
  end
end
