require 'thread'
require 'songbook'
require 'encoder'

class Playlist
  @@list = []
  @@playing = nil
  @@mu = Mutex.new

  @@play_message_seq = 0

  def self.upcomings
    return @@mu.synchronize do
      @@list
    end
  end

  def self.advance()
    return @@mu.synchronize do
      result = nil
      @@list.each do |song|
        if Songbook.downloaded?(song)
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

  def self.next
    advance
    query
  end

  def self.query
    next_song = @@mu.synchronize do
      @@playing
    end

    if next_song.nil?
      broadcast_play nil
    else
      if Encoder.wait_until_ready(next_song)
        broadcast_play next_song
      else
        broadcast_play nil
      end
    end
  end

  def self.append(id)
    should_play_next = @@mu.synchronize do
      @@list << id
      update_encoder_schedule

      @@playing.nil?
    end

    if should_play_next
      Thread.new do
        self.next
      end
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

    def self.broadcast_play(song)
      ActionCable.server.broadcast "playlist_notifications_channel",
        type: 'play',
        url: song.nil? ?
          nil : Rails.application.routes.url_helpers.play_song_path(Song.find(song)),
        seq: @@play_message_seq
      @@play_message_seq += 1
    end
end
