class CreateSongs < ActiveRecord::Migration[5.1]
  def change
    create_table :songs do |t|
      t.string :name
      t.string :artist
      t.string :initial
      t.integer :vocal_track

      t.timestamps
    end
  end
end
