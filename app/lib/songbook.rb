require 'thread'
require 'open-uri'
require 'fileutils'

SONG_FOLDER = Rails.root.join('public/songs/')
SONG_URL = 'http://www.x5bot.com/songmkv/mkv/%d.mpg'

class Songbook
  @@mu = Mutex.new
  @@total_lengths = {}
  @@downloaded_lengths = {}
  @@threads = []

  def self.downloading
    return @@total_lengths.keys
  end

  def self.is_downloaded?(id)
    File.exists?(song_path(id))
  end

  def self.get_status(id)
    if File.exists?(song_path(id))
      return true, 1.0
    end

    progress = nil

    @@mu.synchronize do
      if !@@total_lengths.include?(id)
        progress = nil
      elsif @@total_lengths[id] == 0
        progress = 0.0
      else
        progress = 1.0 * @@downloaded_lengths[id] / @@total_lengths[id]
      end
    end

    return false, progress
  end

  def self.start_download(id)
    downloaded, _ = self.get_status(id)
    if downloaded
      return false
    end

    @@threads << Thread.start do
      @@mu.synchronize do
        @@total_lengths[id] = 0
      end

      song_url = SONG_URL % id

      puts 'Downloading song from ' + song_url

      content = open(song_url, 'rb',
        content_length_proc: lambda do |length|
          @@mu.synchronize do
            @@total_lengths[id] = length
          end
        end,
        progress_proc: lambda do |size|
          @@mu.synchronize do
            @@downloaded_lengths[id] = size
          end
        end
      ).read

      open(self.song_path(id), 'wb') do |f|
        f.write(content)
      end
    end

    return true
  end

  def self.song_path(id)
    FileUtils.mkdir_p(SONG_FOLDER)
    SONG_FOLDER.join("#{id}.mpg")
  end

  private
end
