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
end)

function getClient()
    local serverAddress = os.getenv("PILOSA_BIND")
    if serverAddress == nil then
        serverAddress = "http://localhost:10101"
    end
    return PilosaClient(URI:address(serverAddress))
end
