-- resources.lua
--
-- Implements the various resource types that can be retrieved
-- from the Authy API.

-- External requirements
local json = require 'cjson'

-- Internal requirements
local http = require 'authy.http'
local url = require 'socket.url'

-- Metatables setup
local _M = {
    VERSION = "0.1.0"
}

local mt = {
    __index = _M
}

-- Superclass inheritor function
local function set_superclass(super, new)
    new.__index = new

    setmetatable(new, {
        __index = super,
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:_init(...)
            return self
        end
    })
end

-- Superclass metatable setup
local Resource = {}
Resource.__index = Resource

setmetatable(Resource, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function Resource:_init(api_url, api_key, verify_ssl)
    if api_url == nil then
        error("api_url == nil")
    else
        self.api_url = api_url
    end

    if api_key == nil then
        error("api_key == nil")
    else
        self.api_key = api_key
    end

    if verify_ssl == nil then
        self.verify_ssl = true
    else
        self.verify_ssl = verify_ssl
    end
end

function Resource:post(path, data)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    return self:request("POST", path, data, headers)
end

function Resource:get(path, data)
    return self:request("GET", path, data)
end

function Resource:put(path, data)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    return self:request("PUT", path, data, headers)
end

function Resource:delete(path, data)
    return self:request("DELETE", path, data)
end

function Resource:request(method, path, data, headers)
    if method == nil then
        error("method == nil")
    end

    if path == nil then
        error("path == nil")
    end

    if headers == nil then
        headers = {}
    end

    local url = self.api_url .. path
    local params = {
        ["api_key"] = self.api_key
    }

    if method == "GET" then
        return http.http_request(method, url, params, nil, headers, self.verify_ssl)
    else
        if type(data) == "table" then
            local err, encoded = pcall(json.encode, data)
            if err then
                error(err)
            else
                return http.http_request(method, url, params, encoded, headers, self.verify_ssl)
            end
        else
            return http.http_request(method, url, params, data, headers, self.verify_ssl)
        end
    end
end
_M.Resource = Resource


local Instance = {}
Instance.__index = Instance

setmetatable(Instance, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function Instance:_init(resource, response)
    if resource == nil then
        error("resource == nil")
    else
        self.resource = resource
    end

    if response == nil then
        error("response == nil")
    else
        self.response = response
    end

    if response.body then
        local err, body = pcall(json.decode, response.body)
        if err then
            self.content = response.body
        else
            self.content = body
        end
    end
end

function Instance:ok()
    return self.response.status_code == 200
end

function Instance:errors()
    if self:ok() then
        return {}
    end

    errors = {
        ["error"] = self.content or self.response._error
    }

    return errors
end

function Instance:get(item)
    return self.content[item]
end
_M.Instance = Instance


local SMS = {}
set_superclass(Instance, SMS)

function SMS:ignored()
    if self.content.ignored ~= nil then
        return true
    else
        return false
    end
end
_M.SMS = SMS


-- /users
local User = {}
set_superclass(Instance, User)

function User:_init(resource, response)
    Instance._init(self, resource, response)

    if self.content.user and self.content.user.id then
        self.id = self.content.user.id
    else
        self.id = nil
    end
end
_M.User = User


local Users = {}
set_superclass(Resource, Users)

function Users:create(email, phone, country_code)
    if country_code == nil then
        country_code = 1
    end

    local data = {
        user = {
            ["email"] = email,
            ["phone"] = phone,
            ["country_code"] = country_code,
        }
    }

    local resp = self:post("/users/new", data)

    return User(self, resp)
end

function Users:request_sms(user_id, options)
    if options == nil then
        options = {}
    end

    user_id = url.escape(tostring(user_id))

    local resp = self:get(string.format("/sms/%s", user_id))

    return SMS(self, resp)
end

function Users:status(user_id)
    user_id = url.escape(tostring(user_id))

    local resp = self:get(string.format("/users/%s/status", user_id))

    return User(self, resp)
end

function Users:delete(user_id)
    user_id = url.escape(tostring(user_id))

    local resp = self:post(string.format("/users/%s/delete", user_id))

    return User(self, resp)
end
_M.Users = Users


-- /verify
local Token = {}
set_superclass(Instance, Token)

function Token:ok()
    if Instance.ok(self) then
        if self.response.content.token == "is valid" then
            return true
        else
            return false
        end
    end
end
_M.Token = Token


local Tokens = {}
set_superclass(Resource, Tokens)

function Tokens:verify(device_id, token, options)
    if options == nil then
        options = {}
    end

    self:__validate(token, device_id)

    if options.force == nil then
        options.force = true
    end

    token = url.escape(tostring(token))
    device_id = url.escape(tostring(device_id))

    local resp = self:get(string.format("/verify/%s/%s", token, device_id), options)

    return Token(self, resp)
end

function Tokens:__validate(token, device_id)
    self:__validate_digit(token, "Invalid token. Only digits accepted.")
    self:__validate_digit(device_id, "Invalid Authy ID. Only digits accepted.")

    if token:len() < 6 or token:len() > 10 then
        error("Invalid token. Unexpected length.")
    end
end

function Tokens:__validate_digit(value, message)
    if not value:match('%d+') then
        error(message)
    end
end
_M.Tokens = Tokens


-- /app
local App = {}
set_superclass(Instance, App)
_M.App = App


local Apps = {}
set_superclass(Resource, Apps)

function Apps:fetch()
    local resp = self:get("/app/details")

    return App(self, resp)
end
_M.Apps = Apps


-- /app/stats
local Stats = {}
set_superclass(Instance, Stats)
_M.Stats = Stats


local StatsResource = {}
set_superclass(Resource, StatsResource)

function StatsResource:fetch()
    local resp = self:get("/app/stats")

    return Stats(self, resp)
end
_M.StatsResource = StatsResource


-- /phones
local Phone = {}
set_superclass(Instance, Phone)
_M.Phone = Phone


local Phones = {}
set_superclass(Resource, Phones)

function Phones:verification_start(phone_number, country_code, via, locale)
    if phone_number == nil then
        error("Invalid phone number.")
    end

    if country_code == nil then
        error("Invalid country code.")
    end

    if via == nil then
        via = "sms"
    end

    local options = {
        ["phone_number"] = phone_number,
        ["country_code"] = country_code,
        ["via"] = via,
    }

    if locale then
        options.locale = locale
    end

    local resp = self:post("/phones/verification/start", options)

    return Phone(self, resp)
end

function Phones:verification_check(phone_number, country_code, verification_code)
    if phone_number == nil then
        error("Invalid phone number.")
    end

    if country_code == nil then
        error("Invalid country code.")
    end

    if verification_code == nil then
        error("Invalid verification code.")
    end

    local options = {
        ["phone_number"] = phone_number,
        ["country_code"] = country_code,
        ["verification_code"] = verification_code,
    }

    local resp = self:get("/phones/verification/check", options)

    return Phone(self, resp)
end

function Phones:info(phone_number, country_code)
    if phone_number == nil then
        error("Invalid phone number.")
    end

    if country_code == nil then
        error("Invalid country code.")
    end

    local options = {
        ["phone_number"] = phone_number,
        ["country_code"] = country_code,
    }

    local resp = self:get("/phones/info", options)

    return Phone(self, resp)
end
_M.Phones = Phones

return _M
