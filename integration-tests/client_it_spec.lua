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


local PilosaClient = require "pilosa.client".PilosaClient
local URI = require "pilosa.client".URI
local orm = require "pilosa.orm"

describe("PilosaClient", function()
    local client = getClient()
    local schema = orm.Schema()
    local index = schema:index("test-index")
    local frame = index:frame("test-frame")

    before_each(function()
        client:ensureIndex(index)
        client:ensureFrame(frame)
    end)

    after_each(function()
        client:deleteIndex(index)
    end)

    it("can be created with defaults", function()
        local client = PilosaClient()
        assert.same(URI:default(), client.uri)
        assert.same({}, client.options)
    end)

    it("can send a query", function()
        local client = getClient()
        client:query(frame:setbit(10, 20))        
        local response1 = client:query(frame:bitmap(10))
        local bitmap = response1.result.bitmap
        assert.equals(0, #bitmap.attributes)
        assert.equals(1, table.getn(bitmap.bits))
        assert.same(20, bitmap.bits[1])
    end)

    it("can read status", function()
        local client = getClient()
        local status = client:status()
    end)

    it("can read the schema", function()
        local schema1 = client:schema()
    end)
    
    it("can sync the schema", function()
        local client = getClient()
        local schema1 = orm.Schema()
        local remoteIndex = schema1:index("remote-index-1")
        local remoteFrame = remoteIndex:frame("remote-frame-1")
        local index11 = schema1:index("diff-index1")
        index11:frame("frame1-1")
        index11:frame("frame1-2")
        local index12 = schema1:index("diff-index2")
        index12:frame("frame2-1")
        client:syncSchema(schema1)
    end)
end)

function getClient()
    local serverAddress = os.getenv("PILOSA_BIND")
    if serverAddress == nil then
        serverAddress = "http://localhost:10101"
    end
    return PilosaClient(URI:address(serverAddress))
end
