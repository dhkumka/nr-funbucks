-- Including this file inline as lua require is not working
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
[ "\\" ] = "\\",
[ "\"" ] = "\"",
[ "\b" ] = "b",
[ "\f" ] = "f",
[ "\n" ] = "n",
[ "\r" ] = "r",
[ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
escape_char_map_inv[v] = k
end


local function escape_char(c)
return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
return "null"
end


local function encode_table(val, stack)
local res = {}
stack = stack or {}

-- Circular reference?
if stack[val] then error("circular reference") end

stack[val] = true

if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
    if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
    end
    n = n + 1
    end
    if n ~= #val then
    error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
    table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

else
    -- Treat as an object
    for k, v in pairs(val) do
    if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
    end
    table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
end
end


local function encode_string(val)
return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
-- Check for NaN, -inf and inf
if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
end
return string.format("%.14g", val)
end


local type_func_map = {
[ "nil"     ] = encode_nil,
[ "table"   ] = encode_table,
[ "string"  ] = encode_string,
[ "number"  ] = encode_number,
[ "boolean" ] = tostring,
}


encode = function(val, stack)
local t = type(val)
local f = type_func_map[t]
if f then
    return f(val, stack)
end
error("unexpected type '" .. t .. "'")
end


function json.encode(val)
return ( encode(val) )
end

-- END json.lua
-- Start audit.lua

function has_data_key(table, key)
    return table[key] ~= nil and table[key]["data"] ~= nil
end

function flatten_data_record(table, key)
    table[key]["data_json"] = encode(table[key]["data"])
    table[key]["data"] = nil
end

function cb_json(tag, timestamp, record)
    new_record = record
    code = 0
    if has_data_key(new_record, "request") then
        flatten_data_record(new_record, "request")
        code = 2
    end
    if has_data_key(new_record, "response") then
        flatten_data_record(new_record, "response")
        code = 2
    end

    return code, timestamp, new_record
end

function remove_nested_fields(tag, timestamp, record)
    new_record = record
    code = 0
    if new_record["auth"] ~= nil and new_record["auth"]["policy_results"] ~= nil then
        new_record["auth"]["policy_results"] = nil
        code = 2
    end
    return code, timestamp, new_record
end

function forwarded_for_to_source_ip(tag, timestamp, record)
    new_record = record
    code = 0
    if new_record["request"] ~= nil and new_record["request"]["headers"] ~= nil then
        if new_record["request"]["headers"]["x-forwarded-for"] ~= nil then
            new_record["source"] = {}
            new_record["source"]["ip"] = new_record["request"]["headers"]["x-forwarded-for"][1]
        end
        new_record["request"]["headers"] = nil
        code = 2
    end

    return code, timestamp, new_record
end

function copy_to_new_message(src, dest, record, new_record)
    if record[src] ~= nil then
        new_record[dest] = record[src]
    end
end

function construct_log_message(tag, timestamp, record)
    new_record = {}
    new_record["event.dataset"] = "application.log"
    copy_to_new_message("@message", "message", record, new_record)
    copy_to_new_message("@level", "log.level", record, new_record)
    copy_to_new_message("@module", "log.logger", record, new_record)
    copy_to_new_message("error", "error.message", record, new_record)
    copy_to_new_message("lease_id", "event.id", record, new_record)
    -- ecs
    copy_to_new_message("agent.type", "agent.type", record, new_record)
    copy_to_new_message("agent.version", "agent.version", record, new_record)
    copy_to_new_message("agent.name", "agent.name", record, new_record)
    copy_to_new_message("ecs.version", "ecs.version", record, new_record)
    copy_to_new_message("event.sequence", "event.sequence", record, new_record)
    copy_to_new_message("event.created", "event.created", record, new_record)
    copy_to_new_message("log.file.path", "log.file.path", record, new_record)
    copy_to_new_message("host", "host", record, new_record)
    return 2, timestamp, new_record
end

pathEnvToStandardEnv = {}
pathEnvToStandardEnv["prod"] = "production"
pathEnvToStandardEnv["test"] = "test"
pathEnvToStandardEnv["dev"] = "development"

function path_to_service_target(tag, timestamp, record)
    new_record = record
    code = 0
    if new_record["request"] ~= nil and new_record["request"]["path"] ~= nil then
        local path = new_record["request"]["path"]
        if string.sub(path, 0, 5) == "apps/" then
            local path_segment = {}
            for i in string.gmatch(path, "[^/]+") do
                path_segment[#path_segment + 1] = i
            end
            local env = path_segment[3]
            local project = path_segment[4]
            local service = path_segment[5]
            if env ~= nil and pathEnvToStandardEnv[env] ~= nil then
                record["service.target.environment"] = pathEnvToStandardEnv[env]
                code = 2
            end
            if project ~= nil then
                record["labels.target_project"] = project
                code = 2
            end
            if service ~= nil then
                record["service.target.name"] = service
                code = 2
            end
        end
    end
    return code, timestamp, new_record
end
