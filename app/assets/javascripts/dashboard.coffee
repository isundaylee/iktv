refreshDownloadProgressSpans = ->
  for el in $('[data-role=refresh-download-progress]')
    Rails.fire(el, 'submit')

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
    setInterval refreshDownloadProgressSpans, 1000

    $('#play_next').click ->
      App.playlist_notifications.playNext()
      return false

$(ready)
