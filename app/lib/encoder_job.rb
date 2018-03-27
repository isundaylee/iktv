require 'childprocess'
require 'thread'

ENCODING_OUTPUT_DIR = Rails.root.join('public/encoded')

class EncoderJob
  def initialize(song)
    @song = song
    @process = nil
  end

  def start!
    return false if done?

    input_file = Songbook.song_path(@song.id)
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
    arguments += %W(-g 24)
    arguments += %W(#{output_file})

    Rails.logger.info("FFMPEG encoding command: " + arguments.join(' '))

    @process = ChildProcess.build(*arguments)
    @process.start

    start_monitor_thread

    true
  end

  def started?
    !@process.nil?
  end

  def done?
    File.exists?(done_path)
  end

  def finished?
    @process.nil? || @process.exited?
  end

  def stop!
    return false if finished?

    @process.stop
    true
  end

  def pause!
    return false if finished?

    Process.kill('STOP', @process.pid)
    true
  end

  def resume!
    return false if finished?

    Process.kill('CONT', @process.pid)
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
