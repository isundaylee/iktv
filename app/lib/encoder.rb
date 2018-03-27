require 'thread'
require 'encoder_job'

ENCODING_OUTPUT_DIR = Rails.root.join('public/encoded')

class Encoder
  @@mu_reschedule = Mutex.new

  @@jobs = {}
  @@encoded = []

  @@schedule = []

  # Loading previously downloaded songs upon startup
  Pathname.glob(ENCODING_OUTPUT_DIR.join("**/done")).each do |path|
    id = path.dirname.basename.to_s.to_i
    @@encoded << id
  end

  # Thread that periodically reschedules encoding jobs
  @monitor_thread = Thread.start do
    while true
      reschedule
      sleep 1
    end
  end

  def self.encoded?(id)
    @@encoded.include?(id)
  end

  def self.encoded
    @@encoded.clone
  end

  def self.ready?(id)
    File.exists?(encoded_video_fragment_path(id, 1))
  end

  def self.wait_until_ready(id)
    20.times do
      return true if ready?(id)
      sleep(0.5)
    end

    return false
  end

  def self.update_schedule(schedule)
    @@schedule = schedule
    reschedule
  end

  private
    def self.encoded_video_dir(id)
      ENCODING_OUTPUT_DIR.join(id.to_s)
    end

    def self.encoded_video_path(id)
      encoded_video_dir(id).join("frags.m3u8")
    end

    def self.encoded_video_fragment_path(id, num)
      encoded_video_dir(id).join("frags#{num}.ts")
    end

    def self.done_path(id)
      encoded_video_dir(id).join("done")
    end

    def self.pause_all_except(id)
      @@jobs.keys.each do |job|
        next if job == id
        @@jobs[job].pause!
      end
    end

    def self.start_or_resume(id)
      if @@jobs.keys.include?(id)
        @@jobs[id].resume!
      else
        @@jobs[id] = EncoderJob.new(
          Songbook.downloaded_video_path(id),
          encoded_video_path(id),
          lambda do |exit_code|
            FileUtils.touch(done_path(id)) if exit_code == 0

            @@jobs.delete(id)
            @@encoded << id
          end
        )
      end
    end

    def self.reschedule
      @@mu_reschedule.synchronize do
        # Find the first song in the upcoming schedule that has been downloaded
        # but not yet encoded.
        type = 'upcoming'
        winner = @@schedule.find do |s|
          Songbook.downloaded?(s) && !encoded?(s)
        end

        # If there is no such song, we proceed to resume an existing encoding job.
        if winner.nil?
          type = 'existing'
          winner = @@jobs.keys.first
        end

        # If we don't have any in-progress jobs either, pick something from the
        # backlog -- i.e. the set of songs that have been downloaded but not
        # encoded.
        if winner.nil?
          type = 'backlog'
          winner = Songbook.downloaded.find do |s|
            !encoded?(s)
          end
        end

        if winner.nil?
          Rails.logger.info("Encoder has nothing to do for now.")
          return
        end

        Rails.logger.info("Encoder decided to encode #{winner} (#{type}) now.")
        Rails.logger.info("Encoder backlog count: #{Songbook.downloaded.count - encoded.count}.")

        pause_all_except(winner)
        start_or_resume(winner)
      end
    end
end
