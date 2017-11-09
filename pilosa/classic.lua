--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See 3rdparty_licenses/classic.license.txt for details.
--


local Object = {}
Object.__index = Object


function Object:new()
end


function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end


function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end


return Object