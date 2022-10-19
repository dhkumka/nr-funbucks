-- Space delimited values to array
function sdv2array(s)
    delimiter = "%S+"
    result = {};
    for match in string.gmatch(s, delimiter) do
        table.insert(result, match);
    end
    return result;
end

function isempty(s)
    return s == nil or s == ''
end

function copy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do res[copy(k)] = copy(v) end
    return res
end

function remove_nil_fields(tag, timestamp, record)
    return 2, timestamp, record
end


function add_host_metadata(tag, timestamp, record)
    new_record = record
    if isempty(new_record["host"]) then
        new_record["host"] = {}
    end
    local host = new_record["host"]
    if isempty(host["os"]) then
        host["os"] = {}
    end
    host["os"]["name"] = os.getenv("HOST_OS_NAME")
    host["os"]["type"] = os.getenv("HOST_OS_TYPE")
    host["os"]["family"] = os.getenv("HOST_OS_FAMILY")
    host["os"]["kernel"] = os.getenv("HOST_OS_KERNEL")
    host["os"]["full"] = os.getenv("HOST_OS_FULL")
    host["os"]["version"] = os.getenv("HOST_OS_VERSION")

    host["ip"] = os.getenv("HOST_IP")
    host["mac"] = os.getenv("HOST_MAC")
    host["name"] = os.getenv("HOST_NAME")
    host["hostname"] = os.getenv("HOST_HOSTNAME")
    host["domain"] = os.getenv("HOST_DOMAIN")
    host["architecture"] = os.getenv("HOST_ARCH")

    if not(isempty(host["ip"])) then
        host["ip"] = sdv2array(host["ip"])
    else
        host["ip"] = nil
    end

    if not(isempty(host["mac"])) then
        host["mac"] = sdv2array(host["mac"])
    else
        host["mac"] = nil
    end

    if not(isempty(host["name"])) then
        host["name"] = sdv2array(host["name"])
    else
        host["name"] = nil
    end

    if not(isempty(host["domain"])) then
        host["domain"] = sdv2array(host["domain"])
    else
        host["domain"] = nil
    end

    return 2, timestamp, new_record
end
