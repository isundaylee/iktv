require 'thread'

class Encoder
  @@threads = []
  @@mu = Mutex.new
  @@in_progress = []

  def self.start_encoding(id)
    @@mu.synchronize do
      if @@in_progress.include?(id)
        return false
      end

      if File.exists?(done_path(id))
        return false
      else
        FileUtils.rm_rf(self.frags_folder(id))
        self.frags_folder(id)

        @@in_progress << id

        @@threads << Thread.start do
          original = FFMPEG::Movie.new(Songbook.song_path(id).to_s)
          output_path = manifest_path(id)

          original.transcode(output_path.to_s,
            %w(-b 1000k -vcodec libx264 -hls_time 1 -hls_list_size 0 -f hls -g 24))

          if File.read(manifest_path(id)) =~ /EXT-X-ENDLIST/
            FileUtils.touch(done_path(id))
          end
        end
      end

      return true
    end
  end

  def self.stop_encoding(id)
    # line = `ps aux | grep ffmpeg | grep #{id}`.strip
  end

  def self.frags_folder(id)
    frags_folder = SONG_FOLDER.join("#{id}.frags")
    FileUtils.mkdir_p(frags_folder)
    frags_folder
  end

  def self.manifest_path(id)
    frags_folder(id).join("frags.m3u8")
  end

  def self.lock_path(id)
    frags_folder(id).join("lock")
  end

  def self.done_path(id)
    frags_folder(id).join("done")
  end

  def self.ready_for_streaming?(id)
    return File.exists?(frags_folder(id).join("frags1.ts"))
  end
end
