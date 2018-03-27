App.playlist_notifications = App.cable.subscriptions.create "PlaylistNotificationsChannel",
  connected: ->
    # When the channel connects
    if window.isPlayer
      @lastProcessedPlaySeq = -1

      if !@started
        @started = true
        @playNext()

  disconnected: ->
    # When the channel disconnects

  received: (data) ->
    if window.isPlayer
      if data.type == 'play'
        if data.seq > @lastProcessedPlaySeq
          @lastProcessedPlaySeq = data.seq
          window.playSong(data.url)

  playNext: ->
    @perform('play_next')
