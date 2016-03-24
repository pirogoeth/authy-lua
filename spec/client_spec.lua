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

describe('authy.api.client.create_client', function()
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

    if use_staging then
        describe('correctly chooses staging API URL', function()
            it('returns staging application info', function()
                local apps = api_client.apps:fetch()
                assert.is_not.falsy(apps)

                local app_info = apps.content
                assert.is_true(type(app_info) == "table")

                assert.are.equal(app_info.success, true)
                assert.are.equal(app_info.message, "Application information.")
                assert.is_not.falsy(app_info.app)
                assert.are.equal(app_info.app.app_id, 7)
                assert.are.equal(app_info.app.name, "Sandbox App 6")
            end)
        end)
    else
        describe('correctly chooses production API URL', function()
            it('returns production application info', function()
                local apps = api_client.apps:fetch()
                assert.is_not.falsy(apps)

                local app_info = apps.content
                assert.is_true(type(app_info) == "table")

                assert.are.equal(app_info.success, true)
                assert.is_not.falsy(app_info.app)
            end)
        end)
    end
end)
