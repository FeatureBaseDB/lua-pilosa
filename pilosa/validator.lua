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


local INDEX_NAME = "^[a-z][a-z0-9_-]*$"
local FRAME_NAME = "^[a-z][a-z0-9_-]*$"
local LABEL = "^[a-zA-Z][a-zA-Z0-9_-]*$"
local MAX_INDEX_NAME = 64
local MAX_FRAME_NAME = 64
local MAX_LABEL = 64

function validIndexName(name)
    if #name > MAX_INDEX_NAME then
        return false
    end
    return string.match(name, INDEX_NAME) ~= nil
end

function ensureValidIndexName(name)
    if not validIndexName(name) then
        error(string.format("Invalid index name: %s", name))
    end
end

function validFrameName(name)
    if #name > MAX_FRAME_NAME then
        return false
    end
    return string.match(name, FRAME_NAME) ~= nil
end

function ensureValidFrameName(name)
    if not validFrameName(name) then
        error(string.format("Invalid frame name: %s", name))
    end
end

function validLabel(label)
    if #label > MAX_LABEL then
        return false
    end
    return string.match(label, LABEL) ~= nil
end

function ensureValidLabel(label)
    if not validLabel(label) then
        error(string.format("Invalid label: %s", label))
    end
end

return {
    validIndexName = validIndexName,
    validFrameName = validFrameName,
    validLabel = validLabel,
    ensureValidIndexName = ensureValidIndexName,
    ensureValidFrameName = ensureValidFrameName,
    ensureValidLabel = ensureValidLabel
}