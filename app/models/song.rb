require 'songbook'
require 'encoder'

class Song < ApplicationRecord
  # Helper methods for querying various status of the song.
  def downloaded?
    Songbook.downloaded?(self.id)
  end

  def downloading?
    Songbook.downloading?(self.id)
  end

  def download_status
    Songbook.get_status(self.id)
  end

  def encoded?
    Encoder.encoded?(self.id)
  end

  def encoding?
    Encoder.encoding?(self.id)
  end

  # Helper methods for generating front-facing paths to various files related to
  # the song.
  def downloaded_video_path
    "/songs/#{self.id}.mpg"
  end

  def encoded_video_dir_path
    "/encoded/#{self.id}"
  end
end
