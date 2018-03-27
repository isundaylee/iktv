require 'childprocess'
require 'thread'

class EncoderJob
  def initialize(input_file, output_file, complete_proc)
    @input_file = input_file
    @output_file = output_file
    @process = nil
    @paused = false
    @complete_proc = complete_proc

    FileUtils.mkdir_p(File.dirname(@output_file))

    audio_track_index = FFMPEG::Movie.new(@input_file.to_s).audio_streams[-1][:index]

    arguments = %W(ffmpeg)
    arguments += %W(-y)
    arguments += %W(-i #{@input_file})
    arguments += %W(-map 0:0)
    arguments += %W(-map 0:#{audio_track_index})
    arguments += %W(-b 1000k)
    arguments += %W(-vcodec libx264)
    arguments += %W(-f hls)
    arguments += %W(-hls_time 1)
    arguments += %W(-hls_list_size 0)
    arguments += %W(-live_start_index -10000)
    arguments += %W(-g 24)
    arguments += %W(#{@output_file})

    Rails.logger.info("FFMPEG encoding (#{@input_file}) command: " + arguments.join(' '))

    @process = ChildProcess.build(*arguments)
    @process.start
    Rails.logger.info("FFMPEG encoding (#{@input_file}) started.")

    start_monitor_thread
  end

  def finished?
    @process.exited?
  end

  def running?
    !finished?
  end

  def stop!
    return false if finished?

    @process.stop
    Rails.logger.info("FFMPEG encoding (#{@input_file}) stopped.")
    true
  end

  def pause!
    return false if finished?
    return false if @paused

    Process.kill('STOP', @process.pid)
    @paused = true
    Rails.logger.info("FFMPEG encoding (#{@input_file}) paused.")
    true
  end

  def resume!
    return false if finished?
    return false if !@paused

    Process.kill('CONT', @process.pid)
    @paused = false
    Rails.logger.info("FFMPEG encoding (#{@input_file}) resumed.")
    true
  end

  private

    def start_monitor_thread
      Thread.start do
        @process.wait

        Rails.logger.info("FFMPEG encoding (#{@input_file}) exit code: #{@process.exit_code}")
        @complete_proc.call(@process.exit_code)
      end
    end
end
