
local Object = require "pilosa.classic"

Schema = Object:extend()

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

Index = Object:extend()

function Index:new(name, options)
    self.name = name
    self.options = options or {}
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

Frame = Object:extend()

function Frame:new(index, name, options)
    self.index = index
    self.name = name
    self.options = options or {}
end

function Frame:setbit(rowID, columnID, timestamp)
    local ts = ""
    local query = string.format("SetBit(frame='%s', rowID=%d, columnID=%d%s)", self.name, rowID, columnID, ts)
    return PQLQuery(self.index, query)
end

PQLQuery = Object:extend()

function PQLQuery:new(index, pql)
    self.pql = pql
    self.index = index
end

function PQLQuery:serialize()
    return self.pql
end

PQLBatchQuery = Object:extend()

function PQLBatchQuery:new(index, ...)
    queries = {}
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
    schema = schema
}