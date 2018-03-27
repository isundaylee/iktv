require 'thread'
require 'encoder_job'

class Encoder
  @@threads = []
  @@mu = Mutex.new
  @@in_progress = []

  @@jobs = {}
  @@schedule = []

  @monitor_thread = Thread.start do
    while true
      schedule
      sleep(1)
    end
  end

  def self.update_schedule(ids)
    Rails.logger.info("Updating Encoder schedule to: " + ids.to_s)

    @@schedule = ids.clone
    schedule
  end

  def self.effective_schedule
    effective_schedule = @@schedule.clone

    Songbook.downloaded.each do |id|
      load_job_for_song(id)
    end

    in_progress = []
    backlog = []

    @@jobs.keys.each do |id|
      job = @@jobs[id]

      next if effective_schedule.include?(id)

      if job.running?
        in_progress << id
      else
        backlog << id
      end

      effective_schedule << id
    end

    effective_schedule += in_progress
    effective_schedule += backlog

    effective_schedule.select { |s| Songbook.downloaded?(s) }
  end

  def self.schedule
    @@mu.synchronize do
      @@schedule.each do |id|
        load_job_for_song(id)
      end

      winner = nil
      eff_schedule = effective_schedule
      Rails.logger.info("Effective schedule is: #{eff_schedule}")
      eff_schedule.each do |id|
        if !@@jobs[id].ready?
          winner = id
          break
        end
      end

      Rails.logger.info("Scheduler decided to schedule #{winner} first.")

      @@jobs.keys.each do |id|
        job = @@jobs[id]

        if id == winner
          if !job.started?
            job.start!
          elsif
            job.resume!
          end
        else
          job.pause!
        end
      end
    end
  end

  def self.pause_all()
    @@mu.synchronize do
      @@jobs.values.map(&:pause!)
    end
  end

  def self.start_encoding(id)
    @@mu.synchronize do
      load_job_for_song(id)

      if @@jobs[id].ready? || @@jobs[id].started?
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
