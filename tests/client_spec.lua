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


local URI = require "pilosa.client".URI
local QueryOptions = require "pilosa.client".QueryOptions
local orm = require "pilosa.orm"

describe("pilosa.client.URI class", function()
    local URI = require "pilosa.client".URI

    it ("returns default URI", function()
        local uri = URI:default()
        compareURI(uri, "http", "localhost", 10101)
    end)

    it("parses full address", function()
        local uri = URI:address("http+protobuf://index1.pilosa.com:3333")
        compareURI(uri, "http+protobuf", "index1.pilosa.com", 3333)
    end)

    it("parses ipv4 host", function()
        local uri = URI:address("http+protobuf://192.168.1.26:3333")
        compareURI(uri, "http+protobuf", "192.168.1.26", 3333)
    end)

    it("parses host only", function()
        local uri = URI:address("index1.pilosa.com")
        compareURI(uri, "http", "index1.pilosa.com", 10101)
    end)

    it("parses port only", function()
        local uri = URI:address(":5888")
        compareURI(uri, "http", "localhost", 5888)
    end)

    it("parses host port", function()
        local uri = URI:address("index1.big-data.com:5888")
        compareURI(uri, "http", "index1.big-data.com", 5888)
    end)

    it("parses scheme host", function()
        local uri = URI:address("https://index1.big-data.com")
        compareURI(uri, "https", "index1.big-data.com", 10101)
    end)

    it("parses scheme port", function()
        local uri = URI:address("https://:5553")
        compareURI(uri, "https", "localhost", 5553)
    end)

    it("returns a normalized address", function()
        local uri = URI("https", "big-data.pilosa.com", 6888)
        assert.same("https://big-data.pilosa.com:6888", uri:normalize())
    end)

    it("returns an error on invalid address", function()
        local invalidAddresses = {"foo:bar", "http://foo:", "http://foo:", "foo:", ":bar"}
        for i, addr in ipairs(invalidAddresses) do
            assert.error(function() URI:address(addr) end)
        end
    end)
end)

describe("QueryOptions", function()
    it("encodes options", function()
        local options = QueryOptions{}
        assert.is.same("", options:encode())
        
        options = QueryOptions{
            excludeAttributes = true,
            excludeBits = true,
            columnAttributes = true
        }
        assert.is.same(sortedString("?excludeAttrs=true&excludeBits=true&columnAttrs=true"), sortedString(options:encode()))
    end)
end)

function compareURI(uri, scheme, host, port)
    assert.same(scheme, uri.scheme)
    assert.same(host, uri.host)
    assert.same(port, uri.port)
end

function sortedString(s)
    local ls = {}
    for i = 1, #s do
        table.insert(ls, s:sub(i, i))
    end
    table.sort(ls)
    return table.concat(ls)
end


function getClient()
    local serverAddress = os.getenv("PILOSA_BIND")
    if serverAddress == nil then
        serverAddress = "http://localhost:10101"
    end
    return PilosaClient(URI:address(serverAddress))
end
