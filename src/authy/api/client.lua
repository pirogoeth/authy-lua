-- client.lua
--
-- Entrypoint for Authy API access.

local r = require 'authy.api.resources'

local _default_api = "https://api.authy.com/protected/%s"

local _M = {}

function _M.json_api(api_url)
    if api_url == nil then
        api_url = _default_api
    end

    return string.format(_default_api, "json")
end

function _M.xml_api(api_url)
    if api_url == nil then
        api_url = _default_api
    end

    return string.format(_default_api, "xml")
end

function _M.create_client(api_key, api_url)
    local resources = {
        users = r.Users(api_url, api_key),
        tokens = r.Tokens(api_url, api_key),
        apps = r.Apps(api_url, api_key),
        stats = r.StatsResource(api_url, api_key),
        phones = r.Phones(api_url, api_key),
        credentials = {
            key = api_key,
            url = api_url,
        },
    }

    return resources
end

return _M
