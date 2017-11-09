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
        assert.same(targetDiff12, diff12)
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

    it("can deep copy", function()
        local s1 = orm.Schema()
        local i1 = s1:index("index-1", {timeQuantum=orm.TimeQuantum.YEAR_MONTH})
        local f11 = i1:frame("frame-11")
        local f12 = i1:frame("frame-12")
        assert.same(i1, i1:copy())

        local s2 = orm.Schema()
        local i2 = s2:index("index-1", {timeQuantum=orm.TimeQuantum.YEAR_MONTH})
        assert.same(i2, i1:copy(false))

    end)
end)

describe("Frame", function()
    it("can deep copy", function()
        local s1 = orm.Schema()
        local i1 = s1:index("index-1")
        local f11 = i1:frame("frame-11", {
            inverseEnabled=true,            
            timeQuantum=orm.TimeQuantum.YEAR_MONTH_DAY,
            cacheType=orm.CacheType.RANKED,
            cacheSize=100
        })
        local clone = f11:copy()
        assert.same(f11, clone)
    end)

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