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


local json = require "dkjson"
local Object = require "pilosa.classic"
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
    -- SetBit and ClearBit returns boolean values. We currently do not store them in the response.
    if result == true then
        result = {}
    else
        result = result or {}
    end
    -- Queries such as Bitmap, Union, etc. return bitmap results
    self.bitmap = BitmapResult(result)
    -- Count and Sum queries return the count
    self.count = result.count or 0
    -- Sum query returns the sum
    self.sum = result.sum or 0
    -- TopN returns a list of (ID, count) pairs. We call each of them count result item.
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