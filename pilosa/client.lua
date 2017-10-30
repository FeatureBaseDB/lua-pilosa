local Object = require "pilosa.classic"
local json = require "dkjson"
local http = require "socket.http"
local ltn12 = require "ltn12"

local DEFAULT_SCHEME = "http"
local DEFAULT_HOST = "localhost"
local DEFAULT_PORT = 10101
local PATTERN_SCHEME_HOST_PORT = "^([+a-z]+)://([0-9a-z.-]+):([0-9]+)$"
local PATTERN_SCHEME_HOST = "^([+a-z]+)://([0-9a-z.-]+)$"
local PATTERN_SCHEME_PORT = "^([+a-z]+)://:([0-9]+)$"
local PATTERN_HOST_PORT = "^([0-9a-z.-]+):([0-9]+)$"
local PATTERN_SCHEME = "^([+a-z]+)://$"
local PATTERN_PORT = "^:([0-9]+)$"
local PATTERN_HOST = "^([0-9a-z.-]+)$"
local NO_RESPONSE = 0
local RAW_RESPONSE = 1

PilosaClient = Object:extend()

function PilosaClient:new(uri, options)
    self.uri = uri or URI:default()
    self.options = options or {}
end

function PilosaClient:query(query, options)
    local data = query:serialize()
    local path = string.format("/index/%s/query", query.index.name)
    local response = httpRequest(self, "POST", path, data, nil, RAW_RESPONSE)
    return response
end

function PilosaClient:createIndex(index)
    local data = setmetatable(index.options or {}, {__jsontype = "object"})
    local path = string.format("/index/%s", index.name)
    httpRequest(self, "POST", path, json.encode(data), nil, NO_RESPONSE)
end

function PilosaClient:ensureIndex(index)
    self:createIndex(index)
end

function PilosaClient:createFrame(frame)
    local data = setmetatable(frame.options or {}, {__jsontype = "object"})
    local path = string.format("/index/%s/frame/%s", frame.index.name, frame.name)
    httpRequest(self, "POST", path, json.encode(data), nil, NO_RESPONSE)
end

function PilosaClient:ensureFrame(frame)
    self:createFrame(frame)
end

function httpRequest(client, method, path, data, headers, returnResponse)
    local url = string.format("%s%s", client.uri:normalize(), path)
    data = data or ""
    headers = headers or {}
    headers["content-length"] = #data
    headers["content-type"] = "application/json"
    headers["accept"] = "application/json"

    local chunks = {}
    local sink = nil
    if returnResponse ~= NO_RESPONSE then
        sink = ltn12.sink.table(chunks)
    end
    response, status, responseHeaders = http.request{
        url=url,
        method=method,
        source=ltn12.source.string(data),
        sink=sink,
        headers=headers
    }

    if returnResponse == RAW_RESPONSE then
        return response, status, responseHeaders
    end
    return response
end

URI = Object:extend()

function URI:new(scheme, host, port)
    self.scheme = scheme
    self.host = host
    self.port = port
end

function URI:default()
    return URI(DEFAULT_SCHEME, DEFAULT_HOST, DEFAULT_PORT)
end

function URI:address(address)
    scheme, host, port = parseAddress(address)
    return URI(scheme, host, port)
end

function URI:normalize()
    return string.format("%s://%s:%d", self.scheme, self.host, self.port)
end

function parseAddress(address)
    scheme, host, port = string.match(address, PATTERN_SCHEME_HOST_PORT)
    if scheme ~= nil and host ~= nil and port ~= nil then
        return scheme, host, tonumber(port)
    end
    
    scheme, host = string.match(address, PATTERN_SCHEME_HOST)
    if scheme ~= nil and host ~= nil then
        return scheme, host, DEFAULT_PORT
    end
    
    scheme, port = string.match(address, PATTERN_SCHEME_PORT)
    if scheme ~= nil and port ~= nil then
        return scheme, DEFAULT_HOST, tonumber(port)
    end
    
    host, port = string.match(address, PATTERN_HOST_PORT)
    if host ~= nil and port ~= nil then
        return "http", host, tonumber(port)
    end
    
    scheme = string.match(address, PATTERN_SCHEME)
    if scheme ~= nil then
        return scheme, DEFAULT_HOST, DEFAULT_PORT
    end    
    
    port = string.match(address, PATTERN_PORT)
    if port ~= nil then
        return DEFAULT_SCHEME, DEFAULT_HOST, tonumber(port)
    end

    host = string.match(address, PATTERN_HOST)
    if host ~= nil then
        return DEFAULT_SCHEME, host, DEFAULT_PORT
    end

    error("Not a Pilosa URI")
end

return {
    URI = URI,
    PilosaClient = PilosaClient
}
