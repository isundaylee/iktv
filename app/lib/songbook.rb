require 'thread'
require 'open-uri'
require 'fileutils'
require 'uri'

require 'simple_proxy_client'

SONG_FOLDER = Rails.root.join('public/songs')
SONG_URL = 'http://www.x5bot.com/songmkv/mkv/%d.mpg'

class Songbook
  @@mu = Mutex.new

  @@total_lengths = {}
  @@downloaded_lengths = {}

  @@downloaded = Set.new()

  @@threads = []

  # Loading previously downloaded songs upon startup
  Dir.glob(SONG_FOLDER.join("*.mpg")).each do |path|
    name = File.basename(path)
    id = name.split('.')[0].to_i
    @@downloaded << id
  end

  def self.downloading
    @@total_lengths.keys
  end

  def self.downloading?(id)
    @@total_lengths.include? id
  end

  def self.downloaded
    @@downloaded.clone
  end

  def self.downloaded?(id)
    @@downloaded.include? id
  end

  def self.get_status(id)
    @@mu.synchronize do
      if downloaded?(id)
        next true, 1.0
      elsif downloading?(id)
        next false, 1.0 * @@downloaded_lengths[id] / @@total_lengths[id]
      else
        next false, nil
      end
    end
  end

  def self.start_download(id)
    @@mu.synchronize do
      if downloaded?(id) || downloading?(id)
        false
      else
        @@total_lengths[id] = 1
        @@downloaded_lengths[id] = 0

        @@threads << Thread.start do
          song_url = SONG_URL % id
          last_reported = 0.0

          Rails.logger.info('Downloading song from ' + song_url)

          content_length_proc = lambda do |length|
            @@mu.synchronize do
              @@total_lengths[id] = length
            end
          end

          progress_proc = lambda do |size|
            @@mu.synchronize do
              @@downloaded_lengths[id] = size
            end

            progress = 1.0 * size / @@total_lengths[id]
            if (100 * last_reported).to_i != (100 * progress).to_i
              last_reported = progress
              ActionCable.server.broadcast "songs_notifications_channel",
                type: 'download_progress_update',
                id: id,
                progress: progress
            end
          end

          content = nil
          if ENV['SIMPLE_PROXY_URI'].present?
            proxy_host = ENV['SIMPLE_PROXY_URI'].split(':')[0]
            proxy_port = ENV['SIMPLE_PROXY_URI'].split(':')[1]
            content = simple_proxy_read(proxy_host, proxy_port, song_url,
              content_length_proc: content_length_proc,
              progress_proc: progress_proc
            )
          else
            content = open(song_url, 'rb',
              content_length_proc: content_length_proc,
              progress_proc: progress_proc
            ).read
          end

          open(self.downloaded_video_path(id), 'wb') do |f|
            f.write(content)
          end

          @@mu.synchronize do
            @@downloaded << id

            @@total_lengths.delete(id)
            @@downloaded_lengths.delete(id)
          end
        end

        true
      end
    end
  end

  def self.downloaded_video_path(id)
    FileUtils.mkdir_p(SONG_FOLDER)
    SONG_FOLDER.join("#{id}.mpg")
  end

  private
end
