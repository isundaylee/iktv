refreshDownloadProgressSpans = ->
  for el in $('[data-role=refresh-download-progress]')
    Rails.fire(el, 'submit')

window.playNextSong = ->
  for form in $('#play_next_song_form')
    Rails.fire(form, 'submit')

window.playSong = (path) ->
  console.log('Playing: ' + path)
  $('video')[0].pause()
  $('video source').attr('src', path)
  $('video')[0].load()
  $('video')[0].play()

ready = ->
  setInterval refreshDownloadProgressSpans, 1000

  $('video').bind 'ended', ->
    playNextSong()

$(ready)
