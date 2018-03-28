class App.Player
  constructor: (video) ->
    @video = video
    @usingHLSJS = false

  initialize: ->
    if @video.canPlayType('application/vnd.apple.mpegurl')
      console.log('Using native hls.js support for video playback.')
    else if Hls.isSupported()
      @usingHLSJS = true
      console.log('Using HLS for video playback.')
    else
      alert('You browser does not have HLS playback support. Sorry ):')

    $(@video).on 'ended', =>
      @onSongEndHandler()

  onSongEnd: (handler) ->
    @onSongEndHandler = handler

  stop: ->
    if @usingHLSJS
      if @hls
        @video.pause()
        @hls.destroy()
    else
      @video.pause()

  play: (url) ->
    console.log('Playing URL: ' + url)

    @stop()
    return if !url

    if @usingHLSJS
      @hls = new Hls()
      @hls.attachMedia(@video)
      @hls.on Hls.Events.MEDIA_ATTACHED, =>
        console.log('HLS playing bound successfully.')
        @hls.loadSource(url)
        @hls.on Hls.Events.MANIFEST_PARSED, =>
          @video.play()
    else
      @video.pause()
      $(@video).find('source').attr('src', url)
      @video.load()
      @video.play()
