# Lua Client for Pilosa

<a href="https://github.com/pilosa"><img src="https://img.shields.io/badge/pilosa-master-blue.svg"></a>
<a href="https://travis-ci.org/pilosa/lua-pilosa"><img src="https://api.travis-ci.org/pilosa/lua-pilosa.svg?branch=master"></a>
<a href='https://coveralls.io/github/pilosa/lua-pilosa?branch=master'><img src='https://coveralls.io/repos/github/pilosa/lua-pilosa/badge.svg?branch=master' alt="Coverage Status" /></a>


<img src="https://www.pilosa.com/img/le.svg" style="float: right" align="right" height="301">

Lua client for Pilosa high performance distributed bitmap index. See this article for more information: https://www.pilosa.com/blog/writing-a-client-library/

## What's New?

See: [CHANGELOG](CHANGELOG.md)

## Requirements

* Lua 5.1

## Install

Pilosa client is on [LuaRocks](http://luarocks.org/modules/yucepilosa/pilosa):

```
luarocks install pilosa
```

## Usage

### Quick overview

Assuming [Pilosa](https://github.com/pilosa/pilosa) server is running at `localhost:10101` (the default):

```lua
local PilosaClient = require "pilosa.client".PilosaClient

-- Create the default client
local client = PilosaClient()

-- Retrieve the schema
local schema = client:schema()

-- Create an Index object
local myindex = schema:index("myindex")

-- Create a Frame object
local myframe = myindex:frame("myframe")

-- make sure the index and frame exists on the server
client:syncSchema(schema)

-- Send a SetBit query. An error is thrown if execution of the query fails.
client:query(myframe:setbit(5, 42))

-- Send a Bitmap query. An error is thrown if execution of the query fails.
local response = client:query(myframe:bitmap(5))

-- Get the result
local result = response.result

-- Act on the result
if result ~= nil then
    bits = result.bitmap.bits
    print("Got bits: ", bits)
end

-- You can batch queries to improve throughput
response = client:query(
    myindex:batchQuery(
        myframe:bitmap(5),
        myframe:bitmap(10)
    )    
)
for i, result in ipairs(response.results) do
    -- Act on the result
    print(result)
end
```

## Documentation

### Data Model and Queries

See: [Data Model and Queries](docs/data-model-queries.md)

### Executing Queries

See: [Server Interaction](docs/server-interaction.md)

## Contributing

See: [CONTRIBUTING](CONTRIBUTING.md)

## License

See: [LICENSE](LICENSE)
