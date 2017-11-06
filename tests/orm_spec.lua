local orm = require "pilosa.orm"

local schema = orm.schema()
local index = schema:index("sample-index")
local frame = index:frame("sample-frame")

describe("Schema", function()
    it("can create index", function()
        local index2 = schema:index("sample-index")
        assert.same("sample-index", index2.name)
        -- schema should return the same index instance for the same name
        assert.equals(index, index2)
    end)
end)

describe("Index", function()
    local sampleIndex = schema:index("sample-index")
    local sampleFrame = sampleIndex:frame("sample-frame")
    
    it("can create frame", function()
        local index = schema:index("sample-index")
        assert.same("sample-frame", frame.name)
        assert.equals(index, frame.index)
        local frame2 = index:frame("sample-frame")
        -- frame should return the same frame instance for the same name
        assert.equals(frame, frame2)
    end)

    it("index can create raw query", function()
        local q = index:rawQuery("No validation whatsoever for raw queries")
        assert.same("No validation whatsoever for raw queries", q:serialize())
        assert.equals(index, q.index)
    end)

    it("index can create Union query", function()
        local b1 = sampleFrame:bitmap(10)
        local b2 = sampleFrame:bitmap(20)
        local q = sampleIndex:union(b1, b2)
        local target = "Union(Bitmap(rowID=10, frame='sample-frame'), Bitmap(rowID=20, frame='sample-frame'))"
        assert.same(target, q:serialize())
    end)
end)

describe("Frame", function()
    it("can create bitmap query", function()
        local q = frame:bitmap(5)
        assert.same("Bitmap(rowID=5, frame='sample-frame')", q:serialize())
    end)

    it("can create inverse bitmap query", function()
        local q = frame:inverseBitmap(5)
        assert.same("Bitmap(columnID=5, frame='sample-frame')", q:serialize())
    end)

    it("can create setbit query", function()
        local q = frame:setbit(5, 10)
        assert.same("SetBit(rowID=5, frame='sample-frame', columnID=10)", q:serialize())
    end)

    it("can create setbit query wıth timestamp", function()
        -- timestamp = datetime(2017, 4, 24, 12, 14)
        local ts = os.time{year=2017, month=4, day=24, hour=12, min=14}
        local q = frame:setbit(5, 10, ts)
        assert.same("SetBit(rowID=5, frame='sample-frame', columnID=10, timestamp='2017-04-24T12:14')", q:serialize())
    end)
end)