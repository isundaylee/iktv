refreshDownloadProgressSpans = ->
  for el in $('[data-role=refresh-download-progress]')
    Rails.fire(el, 'submit')


ready = ->
  setInterval refreshDownloadProgressSpans, 1000

$(ready)
