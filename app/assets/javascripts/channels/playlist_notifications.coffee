App.playlist_notifications = App.cable.subscriptions.create "PlaylistNotificationsChannel",
  connected: ->
    console.log('Playlist notification connected.')

    if App.isPlayer
      @lastProcessedPlaySeq = -1

      if !@started
        @started = true
        @query()

  disconnected: ->
    console.log('Playlist notification disconnected.')

  received: (data) ->
    console.log 'Playlist notification received: ' + JSON.stringify(data)
    if App.isPlayer
      if data.type == 'play'
        if data.seq > @lastProcessedPlaySeq
          @lastProcessedPlaySeq = data.seq
          App.player.play(data.url)

  playNext: ->
    @perform('play_next')

  query: ->
    @perform('query')
