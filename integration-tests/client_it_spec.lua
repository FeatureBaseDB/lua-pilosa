local PilosaClient = require "pilosa.client".PilosaClient
local URI = require "pilosa.client".URI
local orm = require "pilosa.orm"

describe("PilosaClient", function()
    local client = getClient()
    local schema = orm.schema()
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
        local response, err = client:query(frame:setbit(555, 10))
        assert.Nil(err)
        assert.True(response.result ~= nil)
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
        local schema1 = orm.schema()
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
