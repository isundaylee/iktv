require 'songbook'

class Playlist
  @@list = []

  def self.pop_next()
    @@list.each do |song|
      if Songbook.get_status(song)[0]
        @@list.delete(song)
        return song
      end
    end

    return nil
  end

  def self.append(id)
    @@list << id
  end

  def self.get_index_of_song(id)
    @@list.index(id)
  end
end
