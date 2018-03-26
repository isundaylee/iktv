playNextSong = ->
  App.playlist_notifications.playNext()

window.playSong = (path) ->
  console.log('Playing: ' + path)

  $('video')[0].pause()
  $('video source').attr('src', path)
  $('video')[0].load()
  $('video')[0].play()

ready = ->
  window.isPlayer = ($('video').length > 0)

  if window.isPlayer
    $('video').bind 'ended', ->
      playNextSong()
  else
    $('#play_next').click ->
      App.playlist_notifications.playNext()
      return false

$(document).on('turbolinks:load', ready)
