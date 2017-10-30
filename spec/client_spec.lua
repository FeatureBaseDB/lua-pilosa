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
        local response = client:query(frame:setbit(555, 10))
        assert.True(response.result ~= nil)
    end)
end)

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

function compareURI(uri, scheme, host, port)
    assert.same(scheme, uri.scheme)
    assert.same(host, uri.host)
    assert.same(port, uri.port)
end

function getClient()
    local serverAddress = os.getenv("PILOSA_BIND")
    if serverAddress == nil then
        serverAddress = "http://localhost:10101"
    end
    return PilosaClient(URI:address(serverAddress))
end
