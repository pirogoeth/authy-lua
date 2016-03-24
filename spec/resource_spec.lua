-- client_spec.lua
--
-- Tests library initialization

-- Rewrite package path
package.path = 'src/?.lua;' .. package.path

local client = require 'authy.api.client'

describe('pre-test', function()
    it('can load AUTHY_KEY envvar', function()
        local var = os.getenv('AUTHY_KEY')
        assert.is_not.falsy(var)
    end)
end)

describe('authy.api.resources', function()
    local api_key = nil
    local api_url = nil
    local use_staging = string.upper(os.getenv('AUTHY_USE_STAGING') or "YES") == "YES"

    local api_client = nil

    it('loads API credentials', function()
        api_key = os.getenv('AUTHY_KEY')

        if use_staging then
            api_url = client.json_api('https://sandbox-api.authy.com/protected/%s')
        elseif not use_staging then
            api_url = client.json_api('https://api.authy.com/protected/%s')
        end

        assert.is.truthy(api_key)
        assert.is.truthy(api_url)
    end)

    it('creates API client', function()
        assert.is.truthy(api_key)
        assert.is.truthy(api_url)

        api_client = client.create_client(api_key, api_url)

        assert.is.truthy(api_client)
    end)

    it('has valid resource instances', function()
        assert.is.truthy(api_client.users)
        assert.is.truthy(api_client.apps)
        assert.is.truthy(api_client.phones)
        assert.is.truthy(api_client.stats)
        assert.is.truthy(api_client.tokens)

        assert.is.truthy(api_client.credentials.key)
        assert.is.truthy(api_client.credentials.url)
    end)

    if use_staging then
    else
    end
end)
