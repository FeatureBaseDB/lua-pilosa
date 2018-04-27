package = "Pilosa"
version = "0.2.0"
source = {
   url = "git://github.com/pilosa/lua-pilosa",
   tag = "v0.2.0"
}
description = {
   summary = "Client Library for Pilosa distributed bitmap index",
   detailed = [[
      Client Library for Pilosa distributed bitmap index
   ]],
   homepage = "https://github.com/pilosa/lua-pilosa",
   license = "BSD"
}
dependencies = {
   "lua >= 5.1, < 5.4",
   "luasocket >= 3.0rc1-2",
   "dkjson >= 2.5-2"
}
build = {
   type = "builtin",
   modules = {
       ["pilosa.orm"] = "pilosa/orm.lua",
       ["pilosa.client"] = "pilosa/client.lua",
       ["pilosa.response"] = "pilosa/response.lua",
       ["pilosa.validator"] = "pilosa/validator.lua",
       ["pilosa.classic"] = "pilosa/classic.lua"
   }
}