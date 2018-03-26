App.playlist_notifications = App.cable.subscriptions.create "PlaylistNotificationsChannel",
  connected: ->
    # When the channel connects
    if window.isPlayer
      @playNext()

  disconnected: ->
    # When the channel disconnects

  received: (data) ->
    if data.type == 'play'
      window.playSong(data.url)

  playNext: ->
    @perform('play_next')
