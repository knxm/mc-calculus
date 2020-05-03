local socket = require "socket"
local meta = {}
meta.__index = meta

-- 新しくMaximaセッションを起動する
local function new()
  local server = assert(socket.bind("*", 0))
  local ip, port = server:getsockname()
  print(ip, port)
  local maxima = assert(io.popen(string.format("maxima --very-quiet -s %d", port)))
  local client = assert(server:accept())
  print("Connection accepted")
  -- maxima:read("*l") -- "Connecting Maxima to server on port XXXXX"
  client:settimeout(10)
  assert(client:receive("*l")) -- "pid=*****"
  return setmetatable({_server = server, _client = client, _process = maxima}, meta)
end

-- Maximaセッションを使ってコマンドを実行する
function meta:run(command)
  command = command:gsub("\n*$", "")
  self._client:send(command..";\n")
  local result = assert(self._client:receive("*l"))
  print("Received", result)
  return (result:gsub("%s", " "))
end

-- Maximaセッションを閉じる
function meta:close()
  self._client:send("quit();\n")
  self._client:close()
  self._process:close()
  self._server:close()
end
return {
  new = new,
}
