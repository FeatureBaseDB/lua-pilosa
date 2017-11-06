local Object = require "pilosa.classic"
local inspect = require 'inspect'
local json = require "dkjson"

local QueryResponse = Object:extend()
local QueryResult = Object:extend()
local BitmapResult = Object:extend()
local CountResultItem = Object:extend()

function QueryResponse:new(response)
    local jsonResponse = json.decode(response)
    local results = {}
    if jsonResponse["results"] ~= nil then
        for i, result in ipairs(jsonResponse["results"]) do
            table.insert(results, QueryResult(result))
        end
    end
    self.results = results
    self.result = results[1]
end

function QueryResult:new(result)
    if result == true then
        result = {}
    else
        result = result or {}
    end
    self.bitmap = BitmapResult(result)
    self.count = result.count or 0
    self.sum = result.sum or 0
    local countItems = {}
    if #result > 0 and result[1].id ~= nil and result[1].count ~= nil then
        for i, item in ipairs(result) do
            table.insert(countItems, CountResultItem(item))
        end
    end
    self.countItems = countItems
end

function BitmapResult:new(result)
    self.bits = result.bits or {}
    self.attributes = result.attrs or {}
end

function CountResultItem:new(id, count)
    self.id = id
    self.count = count
end

return {
    QueryResponse = QueryResponse
}