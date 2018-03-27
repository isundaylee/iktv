require 'thread'
require 'songbook'

class Playlist
  @@list = []
  @@playing = nil
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


      @@playing = result
      update_encoder_schedule

      result
    end
  end

  def self.next()
    pop_next()
    link = nil

    @@mu.synchronize do
      break if @@playing.nil?

      ActionCable.server.broadcast "playlist_notifications_channel",
        type: 'play',
        url: nil

      if Encoder.wait_until_ready(@@playing)
        link = Rails.application.routes.url_helpers.play_song_path(Song.find(@@playing))
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
      update_encoder_schedule
    end
  end

  def self.shuffle
    @@mu.synchronize do
      @@list.shuffle!
      update_encoder_schedule
    end
  end

  def self.move_to_front(id)
    @@mu.synchronize do
      if @@list.include?(id)
        @@list.delete(id)
        @@list.unshift(id)
      end

      update_encoder_schedule
    end
  end

  def self.get_index_of_song(id)
    result = @@mu.synchronize do
      @@list.index(id)
    end

    result
  end

  private
    def self.update_encoder_schedule
      Encoder.update_schedule(([@@playing] + @@list).compact)
    end
end
