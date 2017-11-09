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

describe("validator", function()
    local VALID_INDEX_NAMES = {
        "a", "ab", "ab1", "b-c", "d_e",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }

    local INVALID_INDEX_NAMES = {
        "", "'", "^", "/", "\\", "A", "*", "a:b", "valid?no", "yüce",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1"
    }

    local VALID_FRAME_NAMES = {
        "a", "ab", "ab1", "b-c", "d_e",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }

    local INVALID_FRAME_NAMES = {
        "", "'", "^", "/", "\\", "A", "*", "a:b", "valid?no", "yüce", "_", "-", ".data", "d.e", "1",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1"
    }

    local VALID_LABELS = {
        "a", "ab", "ab1", "d_e", "A", "Bc", "B1", "aB", "b-c",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }

    local INVALID_LABELS = {
        "", "1", "_", "-", "'", "^", "/", "\\", "*", "a:b", "valid?no", "yüce",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1"
    }

    it("validates valid index name", function()
        for i, name in ipairs(VALID_INDEX_NAMES) do
            assert.is_true(validator.validIndexName(name))
        end
    end)

    it("does not validate invalid index name", function()
        for i, name in ipairs(INVALID_INDEX_NAMES) do
            assert.is_false(validator.validIndexName(name))
        end
    end)

    it("validates valid frame name", function()
        for i, name in ipairs(VALID_FRAME_NAMES) do
            assert.is_true(validator.validFrameName(name))
        end
    end)

    it("does not validate invalid frame name", function()
        for i, name in ipairs(INVALID_FRAME_NAMES) do
            assert.is_false(validator.validFrameName(name))
        end
    end)

    it("validates valid label", function()
        for i, label in ipairs(VALID_LABELS) do
            assert.is_true(validator.validLabel(label))
        end
    end)

    it("does not validate invalid label", function()
        for i, label in ipairs(INVALID_LABELS) do
            assert.is_false(validator.validLabel(label))
        end
    end)
end)