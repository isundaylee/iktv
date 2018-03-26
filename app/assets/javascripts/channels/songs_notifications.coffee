App.songs_notifications = App.cable.subscriptions.create "SongsNotificationsChannel",
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    if !window.isPlayer
      if data.type == 'download_progress_update'
        $('.status .progress[data-id=' + data.id.toString() + ']').text(
          Math.floor(100 * data.progress) + "%")
