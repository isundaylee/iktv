require 'thread'
require 'encoder_job'

class Encoder
  @@threads = []
  @@mu = Mutex.new
  @@in_progress = []

  @@jobs = {}

  def self.start_encoding(id)
    @@mu.synchronize do
      load_job_for_song(id)

      if @@jobs[id].done? || @@jobs[id].started?
        false
      else
        @@jobs[id].start!
        true
      end
    end
  end

  def self.stop_all()
    @@mu.synchronize do
      @@jobs.values.each(&:stop!)
      @@jobs = {}
    end
  end

  def self.ready_for_streaming?(id)
    load_job_for_song(id)
    File.exists?(@@jobs[id].fragment_video_path(1))
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

  def self.encoded_video_path(id)
    load_job_for_song(id)
    @@jobs[id].encoded_video_path
  end

  private
    def self.load_job_for_song(id)
      if !@@jobs.keys.include?(id)
        @@jobs[id] = EncoderJob.new(Song.find(id))
        false
      else
        true
      end
    end
end
