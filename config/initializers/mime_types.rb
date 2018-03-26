# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register "application/vnd.apple.mpegurl", :m3u8
Rack::Mime::MIME_TYPES[".m3u8"] = "application/vnd.apple.mpegurl"
