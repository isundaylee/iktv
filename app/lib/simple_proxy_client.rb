require 'socket'
require 'net/http'
require 'uri'

READ_CHUNK_SIZE = 1024 * 1024

def simple_proxy_read(proxy_host, proxy_port, url, content_length_proc: nil, progress_proc: nil)
  s = TCPSocket.new(proxy_host, proxy_port)

  uri = URI.parse(url)
  http = Net::HTTP.start(uri.host, uri.port)
  length = nil
  http.head(uri.request_uri).each do |k, v|
    next unless k == 'content-length'
    length = v.to_i
    break
  end

  if length.nil?
    raise RuntimeError("Failed to retrieve content length for url: " + url)
  end

  content_length_proc.call(length) unless content_length_proc.nil?

  s.print("sget " + url + "\n")
  s.print("bye\n")
  content = ""

  while true
    chunk = s.read(READ_CHUNK_SIZE)
    break if chunk.nil?

    content += chunk

    progress_proc.call(content.size) unless progress_proc.nil?
  end

  content
end