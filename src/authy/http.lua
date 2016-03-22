-- http.lua
--
-- lua-resty-http and lua standalone http interop

-- Package declaration
module('http', package.seeall)
local _M = {}

-- External imports
local json = require 'cjson'

-- Generic function to abstract usage of different HTTP clients
-- based on the current operating environment.
--
-- @param string method: HTTP request method
-- @param string url: Full request url
-- @param table params: Query string args in table form
-- @param string data: Request body
-- @param table headers: Headers to send to the upstream
-- @param boolean ssl_verify: Force certificate name verification
local function http_request(method, url, params, data, headers, ssl_verify)
    if method == nil or url == nil then
        return nil
    end

    if params == nil then
        params = {}
    end

    if headers == nil then
        headers = {}
    end

    if ssl_verify == nil then
        ssl_verify = true
    end

    if ngx ~= nil then
        local ngx_http = require 'resty.http'
        -- The ngx namespace exists, so use ngx_http
        local httpc = ngx_http.new()

        local request_data = {
            ["version"] = 1.0,
            ["method"] = method,
            ["headers"] = headers,
            ["ssl_verify"] = ssl_verify,
        }

        request_data.query = params
        request_data.body = data

        local response, err = httpc:request_uri(url, request_data)
        if response == nil and err then
            -- Request problems
            return {
                status_code = -1,
                headers = nil,
                body = nil,
                response = response,
                _error = err,
            }
        else
            return {
                status_code = response.status,
                headers = response.headers,
                body = response.body or nil,
                response = response,
                _error = nil,
            }
        end
    else
        local lua_http = require 'httpclient'
        -- Use the standalone Lua httpclient module
        local httpcw = lua_http.new()
        local httpc = httpcw.client

        local opts = {}

        opts.body = data
        opts.ssl_opts = {}
        opts.ssl_opts.cafile = "/etc/ssl/cert.pem"
        opts.ssl_opts.protocol = "tlsv1"
        if ssl_verify ~= nil then
            if ssl_verify then
                opts.ssl_opts.verify = "peer"
            else
                opts.ssl_opts.verify = "none"
            end
        end

        local status, response = pcall(httpc.request, httpc, url, params, method, opts)

        if status then
            return {
                status_code = response.code,
                headers = response.headers,
                body = response.body or nil,
                response = response,
                _error = response.err or nil,
            }
        else
            return {
                status_code = -1,
                headers = nil,
                body = nil,
                response = nil,
                _error = response
            }
        end
    end
end
_M.http_request = http_request

return _M
