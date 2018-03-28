ready = ->
  App.isPlayer = ($('video').length > 0)

  if App.isPlayer
    App.player = new App.Player($('video')[0])
    App.player.initialize()
    App.player.onSongEnd ->
      console.log('Current song has ended.')
      App.playlist_notifications.playNext()
  else
    $('#play_next').click ->
      App.playlist_notifications.playNext()
      return false

$(document).on('turbolinks:load', ready)
