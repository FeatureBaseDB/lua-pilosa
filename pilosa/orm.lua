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

function Schema:index(name, options)
    index = self.indexes[name]
    if index == nil then
        index = Index(name, options)
        self.indexes[name] = index
    end
    return index
end

function Index:new(name, options)
    validator.ensureValidIndexName(name)
    self.name = name
    options = options or {}
    self.options = {
        timeQuantum = options.timeQuantum or TimeQuantum.NONE
    }
    -- frames is a weak table
    self.frames = {}
    setmetatable(self.frames, { __mode = "v" })
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

function bitmapOp(index, name, ...)
    local serializedArgs = {}
    for i, a in ipairs(arg) do
        table.insert(serializedArgs, a:serialize())
    end
    local pql = string.format("%s(%s)", name, table.concat(serializedArgs, ", "))
    return PQLQuery(index, pql)
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

function Frame:setbit(rowID, columnID, timestamp)
    local ts = ""
    if timestamp ~= nil then
        ts = string.format(", timestamp='%s'", os.date(TIME_FORMAT, timestamp))
    end
    local query = string.format("SetBit(rowID=%d, frame='%s', columnID=%d%s)", rowID, self.name, columnID, ts)
    return PQLQuery(self.index, query)
end

function Frame:bitmap(rowID)
    local query = string.format("Bitmap(rowID=%d, frame='%s')", rowID, self.name)
    return PQLQuery(self.index, query)
end

function Frame:inverseBitmap(columnID)
    local query = string.format("Bitmap(columnID=%d, frame='%s')", columnID, self.name)
    return PQLQuery(self.index, query)
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
    return table.concat(self.queries)
end

function schema()
    return Schema()
end

return {
    schema = schema,
    TimeQuantum = TimeQuantum,
    CacheType = CacheType
}