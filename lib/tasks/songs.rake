require 'open-uri'

SONGLIST_URL = 'http://www.x5bot.com/songmkv/mkv/song.txt'.freeze

namespace :songs do
  desc 'Download the newest song list from the Internet.'
  task download: :environment do
    puts 'Downloading the newest song list'
    songlist = open(SONGLIST_URL).read.force_encoding('utf-8')

    songs = songlist.lines.drop(1)
    puts 'Number of songs found: ' + songs.count.to_s

    count = 0
    songs.in_groups_of(100, false) do |group|
      group.each do |song|
        fields = song.split('|')

        id = fields[0].to_i
        name = fields[1].strip
        artist = fields[2].strip
        initial = fields[5].strip
        vocal_track = fields[10].to_i

        Song.find_or_create_by!(id: id).update!(
          name: name,
          artist: artist,
          initial: initial,
          vocal_track: vocal_track
        )
      end

      count += group.count
      puts "Processed #{count} songs."
    end
  end

end
