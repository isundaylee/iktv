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
          audio_stream_index = original.audio_streams[-1][:index]
          output_path = manifest_path(id)

          options = %W(-map 0:0 -b 1000k -vcodec libx264 -hls_time 1 -hls_list_size 0 -f hls -g 24)
          original.audio_streams.last(1).each do |as|
            options = ["-map", "0:#{as[:index]}"] + options
          end

          original.transcode(output_path.to_s, options)

          if File.read(manifest_path(id)) =~ /EXT-X-ENDLIST/
            FileUtils.touch(done_path(id))
          end

          @@mu.synchronize do
            @@in_progress.delete(id)
          end
        end
      end

      return true
    end
  end

  def self.stop_all()
    while !@@in_progress.empty?
      stop_encoding(@@in_progress[0])
    end
  end

  def self.stop_encoding(id)
    Rails.logger.info "Stopping encoding for id #{id}"

    line = `ps aux | grep ffmpeg | grep #{id}`.strip

    return if line.empty?

    pid = line.split(/\s+/)[1].to_i
    @@mu.synchronize do
      @@in_progress.delete(id)
    end

    Rails.logger.info "Killing encoding process with PID #{pid}"
    Process.kill('KILL', pid)
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

  def self.wait_until_ready(id)
    20.times do
      if ready_for_streaming?(id)
        return true
      end

      sleep(0.5)
    end

    return true
  end
end
