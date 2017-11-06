
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