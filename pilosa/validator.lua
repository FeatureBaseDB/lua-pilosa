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