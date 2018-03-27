require 'songbook'

class Song < ApplicationRecord
  def status
    Songbook.get_status(self.id)
  end

  def video_path
    '/songs/' + self.id.to_s + '.mpg'
  end

  def encoded_fragments_path
    "/encoded/#{self.id}"
  end
end
