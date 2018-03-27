require 'childprocess'
require 'thread'

ENCODING_OUTPUT_DIR = Rails.root.join('public/encoded')

class EncoderJob
  def initialize(song)
    @song = song
    @process = nil
    @paused = false
  end

  def start!
    return false if ready?

    input_file = Songbook.downloaded_video_path(@song.id)
    output_file = encoded_video_path

    audio_track_index = FFMPEG::Movie.new(input_file.to_s).audio_streams[-1][:index]

    arguments = %W(ffmpeg)
    arguments += %W(-y)
    arguments += %W(-i #{input_file})
    arguments += %W(-map 0:0)
    arguments += %W(-map 0:#{audio_track_index})
    arguments += %W(-b 1000k)
    arguments += %W(-vcodec libx264)
    arguments += %W(-f hls)
    arguments += %W(-hls_time 1)
    arguments += %W(-hls_list_size 0)
    arguments += %W(-live_start_index -10000)
    arguments += %W(-g 24)
    arguments += %W(#{output_file})

    Rails.logger.info("FFMPEG encoding command: " + arguments.join(' '))

    @process = ChildProcess.build(*arguments)
    @process.start
    Rails.logger.info("FFMPEG encoding (#{@song.id}) started.")

    start_monitor_thread

    true
  end

  def started?
    !@process.nil?
  end

  def running?
    started? && !finished?
  end

  def ready?
    File.exists?(done_path)
  end

  def finished?
    @process.nil? || @process.exited?
  end

  def stop!
    return false if !running?

    @process.stop
    Rails.logger.info("FFMPEG encoding (#{@song.id}) stopped.")
    true
  end

  def pause!
    return false if !running?
    return false if @paused

    Process.kill('STOP', @process.pid)
    @paused = true
    Rails.logger.info("FFMPEG encoding (#{@song.id}) paused.")
    true
  end

  def resume!
    return false if !running?
    return false if !@paused

    Process.kill('CONT', @process.pid)
    @paused = false
    Rails.logger.info("FFMPEG encoding (#{@song.id}) resumed.")
    true
  end

  def encoded_video_path
    output_dir.join("frags.m3u8")
  end

  def fragment_video_path(fragment_id)
    output_dir.join("frags#{fragment_id}.ts")
  end

  private
    def output_dir
      output_dir = ENCODING_OUTPUT_DIR.join("#{@song.id}")
      FileUtils.mkdir_p(output_dir)
      output_dir
    end

    def done_path
      output_dir.join('done')
    end

    def start_monitor_thread
      Thread.start do
        @process.wait

        Rails.logger.info("FFMPEG encoding (#{@song.id}) exit code: #{@process.exit_code}")

        if @process.exit_code == 0
          FileUtils.touch(done_path)
        end
      end
    end
end
