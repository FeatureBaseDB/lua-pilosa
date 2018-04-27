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


local orm = require "pilosa.orm"
local schema = orm.Schema()
local index = schema:index("sample-index")
local frame = index:frame("sample-frame")

describe("Schema", function()
    it("can create index", function()
        local index2 = schema:index("sample-index")
        assert.same("sample-index", index2.name)
        -- schema should return the same index instance for the same name
        assert.equals(index, index2)
    end)

    it("can diff another schema", function()
        local schema1 = orm.Schema()
        local index11 = schema1:index("diff-index1")
        index11:frame("frame1-1")
        index11:frame("frame1-2")
        local index12 = schema1:index("diff-index2")
        index12:frame("frame2-1")

        local schema2 = orm.Schema()
        local index21 = schema2:index("diff-index1")
        index21:frame("another-frame")

        local targetDiff12 = orm.Schema()
        local targetIndex1 = targetDiff12:index("diff-index1")
        targetIndex1:frame("frame1-1")
        targetIndex1:frame("frame1-2")
        local targetIndex2 = targetDiff12:index("diff-index2")
        targetIndex2:frame("frame2-1")

        local diff12 = schema1:diff(schema2)
        -- assert.same(targetDiff12, diff12)
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

    it("can create raw query", function()
        local q = index:rawQuery("No validation whatsoever for raw queries")
        assert.same("No validation whatsoever for raw queries", q:serialize())
        assert.equals(index, q.index)
    end)

    it("can create Union query", function()
        local b1 = sampleFrame:bitmap(10)
        local b2 = sampleFrame:bitmap(20)
        local q = sampleIndex:union(b1, b2)
        local target = "Union(Bitmap(row=10, frame='sample-frame'), Bitmap(row=20, frame='sample-frame'))"
        assert.same(target, q:serialize())
    end)

    it("can create Intersect query", function()
        local b1 = sampleFrame:bitmap(10)
        local b2 = sampleFrame:bitmap(20)
        local q = sampleIndex:intersect(b1, b2)
        local target = "Intersect(Bitmap(row=10, frame='sample-frame'), Bitmap(row=20, frame='sample-frame'))"
        assert.same(target, q:serialize())
    end)

    it("cannot create Intersect query with no arguments", function()
        assert.has_errors(function()sampleIndex:intersect() end)
    end)

    it("can create Difference query", function()
        local b1 = sampleFrame:bitmap(10)
        local b2 = sampleFrame:bitmap(20)
        local q = sampleIndex:difference(b1, b2)
        local target = "Difference(Bitmap(row=10, frame='sample-frame'), Bitmap(row=20, frame='sample-frame'))"
        assert.same(target, q:serialize())
    end)

    it("cannot create Difference query with no arguments", function()
        assert.has_errors(function()sampleIndex:difference() end)
    end)

    it("can create Xor query", function()
        local b1 = sampleFrame:bitmap(10)
        local b2 = sampleFrame:bitmap(20)
        local q = sampleIndex:xor(b1, b2)
        local target = "Xor(Bitmap(row=10, frame='sample-frame'), Bitmap(row=20, frame='sample-frame'))"
        assert.same(target, q:serialize())
    end)

    it("cannot create Xor query with no arguments", function()
        assert.has_errors(function()sampleIndex:xor() end)
    end)

    it("can create Count query", function()
        local b1 = sampleFrame:bitmap(10)
        local q = sampleIndex:count(b1)
        local target = "Count(Bitmap(row=10, frame='sample-frame'))"
        assert.same(target, q:serialize())
    end)

    it("can create SetColumnAttrs query", function()
        local q = sampleIndex:setColumnAttrs(10, {foo="bar"})
        local target = "SetColumnAttrs(col=10, foo=\"bar\")"
        assert.same(target, q:serialize())
    end)

    it("can deep copy", function()
        local s1 = orm.Schema()
        local i1 = s1:index("index-1")
        local f11 = i1:frame("frame-11")
        local f12 = i1:frame("frame-12")
        assert.same(i1, i1:copy())

        local s2 = orm.Schema()
        local i2 = s2:index("index-1")
        assert.same(i2, i1:copy(false))
    end)

    it("can create a batch query", function()
        local q = sampleIndex:batchQuery(
            sampleFrame:bitmap(10),
            sampleFrame:bitmap(20)
        )
        local target = "Bitmap(row=10, frame='sample-frame')Bitmap(row=20, frame='sample-frame')"
        assert.same(target, q:serialize())

        q:add(sampleFrame:bitmap(30))
        target = "Bitmap(row=10, frame='sample-frame')Bitmap(row=20, frame='sample-frame')Bitmap(row=30, frame='sample-frame')"
        assert.same(target, q:serialize())
    end)
end)

describe("Frame", function()
    it("can deep copy", function()
        local s1 = orm.Schema()
        local i1 = s1:index("index-1")
        local f11 = i1:frame("frame-11", {
            timeQuantum=orm.TimeQuantum.YEAR_MONTH_DAY,
            cacheType=orm.CacheType.RANKED,
            cacheSize=100
        })
        f11:field("my-field")
        local clone = f11:copy()
        assert.same(f11, clone)
    end)

    it("can create Bitmap query", function()
        local q = frame:bitmap(5)
        assert.same("Bitmap(row=5, frame='sample-frame')", q:serialize())
    end)

    it("can create SetBit query", function()
        local q = frame:setbit(5, 10)
        assert.same("SetBit(row=5, frame='sample-frame', col=10)", q:serialize())
    end)

    it("can create SetBit query with timestamp", function()
        local ts = os.time{year=2017, month=4, day=24, hour=12, min=14}
        local q = frame:setbit(5, 10, ts)
        assert.same("SetBit(row=5, frame='sample-frame', col=10, timestamp='2017-04-24T12:14')", q:serialize())
    end)

    it("can create ClearBit query", function()
        local q = frame:clearbit(5, 10)
        assert.same("ClearBit(row=5, frame='sample-frame', col=10)", q:serialize())
    end)
    
    it("can create SetRowAttrs query", function()
        local q = frame:setRowAttrs(10, {foo="bar"})
        local target = "SetRowAttrs(row=10, frame='sample-frame', foo=\"bar\")"
        assert.same(target, q:serialize())
    end)

    it("can create TopN query", function()
        local q = frame:topn(27)
        local target = "TopN(frame='sample-frame',n=27)"
        assert.same(target, q:serialize())

        q = frame:topn(27, frame:bitmap(10))
        target = "TopN(Bitmap(row=10, frame='sample-frame'),frame='sample-frame',n=27)"
        assert.same(target, q:serialize())
    end)

    it("can create Range query", function()
        local startTime = os.time{year=1970, month=1, day=1, hour=0, min=0}
        local endTime = os.time{year=2000, month=2, day=2, hour=3, min=4}
        local q = frame:range(10, startTime, endTime)
        local target = "Range(row=10, frame='sample-frame', start='1970-01-01T00:00', end='2000-02-02T03:04')"
        assert.same(target, q:serialize())
    end)
end)

describe("RangeField", function()
    local field = frame:field("foo")

    it("can create < query", function()
        local target = "Range(frame='sample-frame', foo < 10)"
        assert.same(target, field:lt(10):serialize())
    end)

    it("can create <= query", function()
        local target = "Range(frame='sample-frame', foo <= 10)"
        assert.same(target, field:lte(10):serialize())
    end)

    it("can create > query", function()
        local target = "Range(frame='sample-frame', foo > 10)"
        assert.same(target, field:gt(10):serialize())
    end)

    it("can create >= query", function()
        local target = "Range(frame='sample-frame', foo >= 10)"
        assert.same(target, field:gte(10):serialize())
    end)

    it("can create == query", function()
        local target = "Range(frame='sample-frame', foo == 10)"
        assert.same(target, field:equals(10):serialize())
    end)

    it("can create != query", function()
        local target = "Range(frame='sample-frame', foo != 10)"
        assert.same(target, field:notEquals(10):serialize())
    end)

    it("can create not null query", function()
        local target = "Range(frame='sample-frame', foo != null)"
        assert.same(target, field:notNull():serialize())
    end)

    it("can create >< query", function()
        local target = "Range(frame='sample-frame', foo >< [10,20])"
        assert.same(target, field:between(10, 20):serialize())
    end)

    it("can create Sum query", function()
        local target = "Sum(Bitmap(row=10, frame='sample-frame'), frame='sample-frame', field='foo')"
        local q = field:sum(frame:bitmap(10))
        assert.same(target, q:serialize())
    end)

    it("can create Min query", function()
        local target = "Min(Bitmap(row=10, frame='sample-frame'), frame='sample-frame', field='foo')"
        local q = field:min(frame:bitmap(10))
        assert.same(target, q:serialize())
    end)

    it("can create Max query", function()
        local target = "Max(Bitmap(row=10, frame='sample-frame'), frame='sample-frame', field='foo')"
        local q = field:max(frame:bitmap(10))
        assert.same(target, q:serialize())
    end)

end)