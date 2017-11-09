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


local validator = require "pilosa.validator"
local Object = require "pilosa.classic"

local Schema = Object:extend()
local Index = Object:extend()
local Frame = Object:extend()
local PQLQuery = Object:extend()
local PQLBatchQuery = Object:extend()

local TimeQuantum = {
    NONE = "",
    YEAR = "Y",
    MONTH = "M",
    DAY = "D",
    HOUR = "H",
    YEAR_MONTH = "YM",
    MONTH_DAY = "MD",
    DAY_HOUR = "DH",
    YEAR_MONTH_DAY = "YMD",
    MONTH_DAY_HOUR = "MDH",
    YEAR_MONTH_DAY_HOUR = "YMDH"
}

local CacheType = {
    DEFAULT = "",
    LRU = "lru",
    RANKED = "ranked"
}

local TIME_FORMAT = "%Y-%m-%dT%H:%M"

function Schema:new()
    self.indexes = {}
end

function Schema:index(name)
    index = self.indexes[name]
    if index == nil then
        index = Index(name)
        self.indexes[name] = index
    end
    return index
end

function Schema:diff(otherSchema)
    local result = Schema()
    for indexName, index in pairs(self.indexes) do
        if otherSchema.indexes[indexName] == nil then
            -- if the index doesn't exist in the other schema, simply copy it
            result.indexes[indexName] = index:copy()
        else
            -- the index exists in the other schema; check the frames
            local resultIndex = index:copy(false)
            local resultIndexUpdated = false
            for frameName, frame in pairs(index.frames) do
                -- if the frame doesn't exist in the other scheme, copy it
                if resultIndex.frames[frameName] == nil then
                    resultIndex.frames[frameName] = frame:copy()
                    resultIndexUpdated = true
                end
            end
            -- check whether we modified result index
            if resultIndexUpdated then
                result.indexes[indexName] = resultIndex
            end
        end
    end
    return result
end

function Index:new(name)
    validator.ensureValidIndexName(name)
    self.name = name
    -- frames is a weak table
    self.frames = {}
    setmetatable(self.frames, { __mode = "v" })
end

function Index:copy(copyFrames)
    if copyFrames == nil then
        copyFrames = true
    end
    local clone = Index(self.name)
    if copyFrames then
        for frameName, frame in pairs(self.frames) do
            clone.frames[frameName] = frame:copy()
        end
    end
    return clone
end

function Index:frame(name, options)
    local frame = self.frames[name]
    if frame == nil then
        frame = Frame(self, name, options)
        self.frames[name] = frame
    end
    return frame
end

function Index:rawQuery(query)
    return PQLQuery(self, query)
end

function Index:batchQuery(...)
    return PQLBatchQuery(self, unpack(arg))
end

function Index:union(...)
    return bitmapOp(self, "Union", unpack(arg))
end

function Index:intersect(...)
    if #arg < 1 then
        error("Number of bitmap queries should be greater than or equal to 1")
    end
    return bitmapOp(self, "Intersect", unpack(arg))
end

function Index:difference(...)
    if #arg < 1 then
        error("Number of bitmap queries should be greater than or equal to 1")
    end
    return bitmapOp(self, "Difference", unpack(arg))
end

function Index:xor(...)
    if #arg < 2 then
        error("Number of bitmap queries should be greater than or equal to 2")
    end
    return bitmapOp(self, "Xor", unpack(arg))
end

function Index:count(bitmap)
    return PQLQuery(self, string.format("Count(%s)", bitmap:serialize()))
end

function Index:setColumnAttrs(columnID, attrs)
    local query = string.format("SetColumnAttrs(columnID=%d, %s)", columnID, createAttributesString(attrs))
    return PQLQuery(self, query)
end

function bitmapOp(index, name, ...)
    local serializedArgs = {}
    for i, a in ipairs(arg) do
        table.insert(serializedArgs, a:serialize())
    end
    local pql = string.format("%s(%s)", name, table.concat(serializedArgs, ", "))
    return PQLQuery(index, pql)
end

function createAttributesString(attrs)
    attrs = attrs or {}
    local attrsList = {}
    for k, v in pairs(attrs) do
        validator.ensureValidLabel(k)
        table.insert(attrsList, string.format("%s=%s", k, json.encode(v)))
    end
    return table.concat(attrsList)
end

function Frame:new(index, name, options)
    validator.ensureValidFrameName(name)
    self.index = index
    self.name = name
    options = options or {}
    self.options = {
        timeQuantum = options.timeQuantum or TimeQuantum.NONE,
        inverseEnabled = options.inverseEnabled or false,
        cacheType = options.cacheType or CacheType.DEFAULT,
        cacheSize = options.cacheSize or 0
    }
end

function Frame:copy()
    return Frame(self.index, self.name, {
        timeQuantum = self.options.timeQuantum,
        inverseEnabled = self.options.inverseEnabled,
        cacheType = self.options.cacheType,
        cacheSize = self.options.cacheSize
    })
end

function Frame:bitmap(rowID)
    local query = string.format("Bitmap(rowID=%d, frame='%s')", rowID, self.name)
    return PQLQuery(self.index, query)
end

function Frame:inverseBitmap(columnID)
    local query = string.format("Bitmap(columnID=%d, frame='%s')", columnID, self.name)
    return PQLQuery(self.index, query)
end

function Frame:setbit(rowID, columnID, timestamp)
    local ts = ""
    if timestamp ~= nil then
        ts = string.format(", timestamp='%s'", os.date(TIME_FORMAT, timestamp))
    end
    local query = string.format("SetBit(rowID=%d, frame='%s', columnID=%d%s)", rowID, self.name, columnID, ts)
    return PQLQuery(self.index, query)
end

function Frame:clearbit(rowID, columnID)
    local query = string.format("ClearBit(rowID=%d, frame='%s', columnID=%d)", rowID, self.name, columnID)
    return PQLQuery(self.index, query)
end

function Frame:topn(n, bitmap)
    return topn(self, n, bitmap, false)
end

function Frame:inverseTopn(n, bitmap)
    return topn(self, n, bitmap, true)
end

function Frame:range(rowID, startTimestamp, endTimestamp)
    return range(self, "rowID", rowID, startTimestamp, endTimestamp)
end

function Frame:inverseRange(columnID, startTimestamp, endTimestamp)
    return range(self, "columnID", columnID, startTimestamp, endTimestamp)
end

function Frame:setRowAttrs(rowID, attrs)
    local query = string.format("SetRowAttrs(rowID=%d, frame='%s', %s)",
        rowID, self.name, createAttributesString(attrs))
    return PQLQuery(self, query)
end

function topn(frame, n, bitmap, inverse)
    local inverseStr = "false"
    if inverse then
        inverseStr = true
    end
    local parts = {
        string.format("frame='%s'", frame.name),
        string.format("n=%d", n),
        string.format("inverse=%s", inverseStr)
    }
    if bitmap ~= nil then
        table.insert(parts, 1, bitmap:serialize())
    end
    local query = string.format("TopN(%s)", table.concat(parts, ","))
    return PQLQuery(frame.index, query)
end

function range(frame, label, rowColumnID, startTimestamp, endTimestamp)
    local startStr = os.date(TIME_FORMAT, startTimestamp)
    local endStr = os.date(TIME_FORMAT, endTimestamp)
    local query = string.format("Range(%s=%d, frame='%s', start='%s', end='%s')",
        label, rowColumnID, frame.name, startStr, endStr)
    return PQLQuery(frame.index, query)
end

function PQLQuery:new(index, pql)
    self.pql = pql
    self.index = index
end

function PQLQuery:serialize()
    return self.pql
end

function PQLBatchQuery:new(index, ...)
    local queries = {}
    for i, v in ipairs(arg) do
        table.insert(queries, v:serialize())
    end
    self.queries = queries
end

function PQLBatchQuery:add(query)
    table.insert(self.queries, query:serialize())
end

function PQLBatchQuery:serialize()
    -- concatenate serialized queries as a string
    return table.concat(self.queries)
end

return {
    Schema = Schema,
    TimeQuantum = TimeQuantum,
    CacheType = CacheType
}