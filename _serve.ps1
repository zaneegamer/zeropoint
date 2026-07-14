$root = "C:\Users\zfjr1\shooting-game"
$port = 8080
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$listener.Start()
Write-Host "Serving $root on port $port"

$mime = @{
  '.html'='text/html'; '.htm'='text/html'; '.js'='application/javascript'
  '.css'='text/css'; '.json'='application/json'; '.png'='image/png'
  '.jpg'='image/jpeg'; '.svg'='image/svg+xml'; '.ico'='image/x-icon'
}

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $requestLine = $reader.ReadLine()
    while ($reader.ReadLine()) {} # drain headers

    $path = "/raycaster.html"
    if ($requestLine -match '^GET\s+(\S+)\s+HTTP') {
      $p = $matches[1]
      if ($p -ne "/") { $path = $p }
    }
    $path = [System.Uri]::UnescapeDataString($path.Split('?')[0])
    $filePath = Join-Path $root ($path.TrimStart('/'))
    $full = [System.IO.Path]::GetFullPath($filePath)

    if ($full.StartsWith($root) -and (Test-Path $full -PathType Leaf)) {
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ext = [System.IO.Path]::GetExtension($full)
      $ct = $mime[$ext]; if (-not $ct) { $ct = 'application/octet-stream' }
      $header = "HTTP/1.1 200 OK`r`nContent-Type: $ct`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
      $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($headerBytes, 0, $headerBytes.Length)
      $stream.Write($bytes, 0, $bytes.Length)
    } else {
      $body = [System.Text.Encoding]::ASCII.GetBytes("404 Not Found: $path")
      $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
      $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($headerBytes, 0, $headerBytes.Length)
      $stream.Write($body, 0, $body.Length)
    }
    $stream.Flush()
  } catch {
    Write-Host "Error: $_"
  } finally {
    $client.Close()
  }
}
