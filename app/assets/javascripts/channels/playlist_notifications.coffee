App.playlist_notifications = App.cable.subscriptions.create "PlaylistNotificationsChannel",
  connected: ->
    # When the channel connects
    if App.isPlayer
      @lastProcessedPlaySeq = -1

      if !@started
        @started = true
        @query()

  disconnected: ->
    # When the channel disconnects

  received: (data) ->
    if App.isPlayer
      if data.type == 'play'
        if data.seq > @lastProcessedPlaySeq
          @lastProcessedPlaySeq = data.seq
          App.player.play(data.url)

  playNext: ->
    @perform('play_next')

  query: ->
    @perform('query')
