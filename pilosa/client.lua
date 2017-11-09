-- Copyright 2017 Pilosa Corp.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
-- 1. Redistributions of source code must retain the above copyright
-- notice, this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- 3. Neither the name of the copyright holder nor the names of its
-- contributors may be used to endorse or promote products derived
-- from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
-- CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
-- INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
-- BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
-- DAMAGE.


local Object = require "pilosa.classic"
local QueryResponse = require "pilosa.response".QueryResponse
local orm = require "pilosa.orm"
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
local HTTP_CONFLICT = 409

local QueryOptions = Object:extend()
local PilosaClient = Object:extend()
local URI = Object:extend()

function PilosaClient:new(uri, options)
    self.uri = uri or URI:default()
    self.options = options or {}
end

function PilosaClient:query(query, options)
    options = QueryOptions(options)
    local data = query:serialize()
    local path = string.format("/index/%s/query%s", query.index.name, options:encode())
    local response = httpRequest(self, "POST", path, data)
    return QueryResponse(response)
end

function PilosaClient:createIndex(index)
    local path = string.format("/index/%s", index.name)
    httpRequest(self, "POST", path, "{}")
end

function PilosaClient:ensureIndex(index)
    local response, err = pcall(function() self:createIndex(index) end)
    if err ~= nil and err.code ~= HTTP_CONFLICT then
        error(err)
    end
end

function PilosaClient:createFrame(frame)
    local data = {options = frame.options}
    local path = string.format("/index/%s/frame/%s", frame.index.name, frame.name)
    httpRequest(self, "POST", path, json.encode(data))
end

function PilosaClient:ensureFrame(frame)
    local response, err = pcall(function() self:createFrame(frame) end)
    if err ~= nil and err.code ~= HTTP_CONFLICT then
        error(err)
    end
end

function PilosaClient:deleteIndex(index)
    local path = string.format("/index/%s", index.name)
    httpRequest(self, "DELETE", path)
end

function PilosaClient:deleteFrame(index)
    local path = string.format("/index/%s/frame/%s", frame.index.name, frame.name)
    httpRequest(self, "DELETE", path)
end    

function PilosaClient:status()
    local response = httpRequest(self, "GET", "/status")
    return json.decode(response)["status"]
end

function PilosaClient:schema()
    local status = self:status()
    local nodes = status["Nodes"]
    local schema = orm.Schema()
    for i, indexInfo in ipairs(nodes[1]["Indexes"] or {}) do
        local meta = indexInfo["Meta"]
        local index = schema:index(indexInfo["Name"])
        for i, frameInfo in ipairs(indexInfo["Frames"] or {}) do
            meta = frameInfo["Meta"]
            index:frame(frameInfo["Name"], {
                cacheSize = meta["CacheSize"],
                cacheType = meta["CacheType"],
                inverseEnabled = meta["InverseEnabled"] or false,
                timeQuantum = meta["TimeQuantum"] or orm.TimeQuantum.NONE
            })
        end
    end
    return schema
end

function PilosaClient:syncSchema(schema)
    local serverSchema = self:schema()
    -- find out local - remote schema
    local diffSchema = schema:diff(serverSchema)
    -- create indexes and frames which doesn't exist on the server side
    for indexName, index in pairs(diffSchema.indexes) do
        if serverSchema.indexes[indexName] == nil then
            self:ensureIndex(index)
        end
        for frameName, frame in pairs(index.frames) do
            self:ensureFrame(frame)
        end
    end
    -- find out remote - local schema
    diffSchema = serverSchema:diff(schema)
    for indexName, index in pairs(diffSchema.indexes) do
        local localIndex = schema.indexes[indexName]
        if localIndex == nil then
            schema.indexes[indexName] = index
        else
            for frameName, frame in pairs(index.frames) do
                localIndex.frames[frameName] = frame
            end
        end
    end
end

function httpRequest(client, method, path, data)
    data = data or ""
    local url = string.format("%s%s", client.uri:normalize(), path)
    local chunks = {}

    local r, status = http.request{
        url=url,
        method=method,
        source=ltn12.source.string(data),
        sink=ltn12.sink.table(chunks),
        headers=getHeaders(data)
    }

    if r == nil then
        -- status contains the error string
        error({error=status, code=0})
    end

    local response = table.concat(chunks)

    if status < 200 or status >= 300 then
        error({error=response, code=status})
    end

    return response
end

function getHeaders(data)
    return {
        -- Content Length is the size of the data
        ["content-length"] = #data,
        ["content-type"] = "application/json",
        ["accept"] = "application/json"
    }
end

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

function QueryOptions:new(options)
    options = options or {}
    self.options = {
        columnAttrs = options.columnAttributes == true,
        excludeAttrs = options.excludeAttributes == true,
        excludeBits = options.excludeBits == true
    }
end

function QueryOptions:encode()
    local parts = {}
    for k, v in pairs(self.options) do
        if v then
            table.insert(parts, string.format("%s=%s", k, tostring(v)))
        end
    end
    if #parts == 0 then
        return ""
    end
    return string.format("?%s", table.concat(parts, "&"))
end

return {
    URI = URI,
    PilosaClient = PilosaClient,
    QueryOptions = QueryOptions
}
