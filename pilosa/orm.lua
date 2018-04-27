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


local json = require ("dkjson")
local validator = require "pilosa.validator"
local Object = require "pilosa.classic"

local Schema = Object:extend()
local Index = Object:extend()
local Frame = Object:extend()
local RangeField = Object:extend(   )
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
    local index = self.indexes[name]
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

function Index:setColumnAttrs(col, attrs)
    local query = string.format("SetColumnAttrs(col=%d, %s)", col, createAttributesString(attrs))
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
        cacheType = options.cacheType or CacheType.DEFAULT,
        cacheSize = options.cacheSize or 0
    }
    -- frames is a weak table
    self.fields = {}
    setmetatable(self.fields, { __mode = "v" })
end

function Frame:copy()
    local f = Frame(self.index, self.name, {
        timeQuantum = self.options.timeQuantum,
        cacheType = self.options.cacheType,
        cacheSize = self.options.cacheSize
    })
    for k, field in pairs(self.fields) do
        f.fields[k] = field
    end
    return f
end

function Frame:bitmap(row)
    local query = string.format("Bitmap(row=%d, frame='%s')", row, self.name)
    return PQLQuery(self.index, query)
end

function Frame:setbit(row, col, timestamp)
    local ts = ""
    if timestamp ~= nil then
        ts = string.format(", timestamp='%s'", os.date(TIME_FORMAT, timestamp))
    end
    local query = string.format("SetBit(row=%d, frame='%s', col=%d%s)", row, self.name, col, ts)
    return PQLQuery(self.index, query)
end

function Frame:clearbit(row, col)
    local query = string.format("ClearBit(row=%d, frame='%s', col=%d)", row, self.name, col)
    return PQLQuery(self.index, query)
end

function Frame:topn(n, bitmap)
    return topn(self, n, bitmap, false)
end

function Frame:range(row, startTimestamp, endTimestamp)
    local startStr = os.date(TIME_FORMAT, startTimestamp)
    local endStr = os.date(TIME_FORMAT, endTimestamp)
    local query = string.format("Range(row=%d, frame='%s', start='%s', end='%s')",
        row, self.name, startStr, endStr)
    return PQLQuery(self.index, query)
end

function Frame:setRowAttrs(row, attrs)
    local query = string.format("SetRowAttrs(row=%d, frame='%s', %s)",
        row, self.name, createAttributesString(attrs))
    return PQLQuery(self, query)
end

function Frame:field(name)
    local field = self.fields[name]
    if field == nil then
        field = RangeField(self, name)
        self.fields[name] = field
    end
    return field
end

function topn(frame, n, bitmap)
    local parts = {
        string.format("frame='%s'", frame.name),
        string.format("n=%d", n),
    }
    if bitmap ~= nil then
        table.insert(parts, 1, bitmap:serialize())
    end
    local query = string.format("TopN(%s)", table.concat(parts, ","))
    return PQLQuery(frame.index, query)
end


function RangeField:new(frame, name)
    validator.ensureValidLabel(name)
    self.frame = frame
    self.name = name
end

function RangeField:lt(n)
    return fieldBinaryOperation(self, "<", n)
end

function RangeField:lte(n)
    return fieldBinaryOperation(self, "<=", n)
end

function RangeField:gt(n)
    return fieldBinaryOperation(self, ">", n)
end

function RangeField:gte(n)
    return fieldBinaryOperation(self, ">=", n)
end

function RangeField:equals(n)
    return fieldBinaryOperation(self, "==", n)
end

function RangeField:notEquals(n)
    return fieldBinaryOperation(self, "!=", n)
end

function RangeField:notNull()
    qry = string.format("Range(frame='%s', %s != null)", self.frame.name, self.name)
    return PQLQuery(self.frame.index, qry)
end

function RangeField:between(a, b)
    qry = string.format("Range(frame='%s', %s >< [%d,%d])", self.frame.name, self.name, a, b)
    return PQLQuery(self.frame.index, qry)
end

function RangeField:sum(bitmap)
    return fieldValQuery(self, "Sum", bitmap)
end

function RangeField:min(bitmap)
    return fieldValQuery(self, "Min", bitmap)
end

function RangeField:max(bitmap)
    return fieldValQuery(self, "Max", bitmap)
end

function fieldBinaryOperation(field, op, n)
    qry = string.format("Range(frame='%s', %s %s %d)", field.frame.name, field.name, op, n)
    return PQLQuery(field.frame.index, qry)
end

function fieldValQuery(field, op, bitmap)
	bitmapStr = ""
	if bitmap ~= nil then
		bitmapStr = string.format("%s, ", bitmap:serialize())
    end
	qry = string.format("%s(%sframe='%s', field='%s')", op, bitmapStr, field.frame.name, field.name)
	return PQLQuery(field.frame.index, qry)
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
    self.index = index
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