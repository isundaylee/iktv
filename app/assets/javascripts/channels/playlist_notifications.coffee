App.playlist_notifications = App.cable.subscriptions.create "PlaylistNotificationsChannel",
  connected: ->
    console.log("CONNECTED")
    window.playNextSong()

  disconnected: ->
    console.log("DISCONNECTED")

  received: (data) ->
    if data.type == 'play'
      window.playSong(data.url)
