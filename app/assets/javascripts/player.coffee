class App.Player
  constructor: (video) ->
    @video = video
    @usingHLS = false

  initialize: ->
    if Hls.isSupported()
      @usingHLS = true
      console.log('Using HLS for video playback.')
    else if @video.canPlayType('application/vnd.apple.mpegurl')
      console.log('Using native HLS support for video playback.')
    else
      alert('You browser does not have HLS playback support. Sorry ):')

    $(@video).on 'ended', =>
      @onSongEndHandler()

  onSongEnd: (handler) ->
    @onSongEndHandler = handler

  stop: ->
    if @usingHLS
      if @hls
        @video.pause()
        @hls.destroy()
    else
      # TODO

  play: (url) ->
    console.log('Playing URL: ' + url)

    @stop()
    return if !url

    if @usingHLS
      @hls = new Hls()
      @hls.attachMedia(@video)
      @hls.on Hls.Events.MEDIA_ATTACHED, =>
        console.log('HLS playing bound successfully.')
        @hls.loadSource(url)
        @hls.on Hls.Events.MANIFEST_PARSED, =>
          @video.play()
    else
      # TODO
