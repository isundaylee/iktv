require 'songbook'

class Song < ApplicationRecord
  def status
    Songbook.get_status(self.id)
  end

  def video_path
    '/songs/' + self.id.to_s + '.mpg'
  end

  def play_path
    "/encoded/#{self.id}/frags.m3u8"
  end
end
