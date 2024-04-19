local CACHED = {
    USERS = {}
}

local Config <const> = DISCORD_CONFIG
local formattedToken<const> = ("Bot %s"):format(Config.BotToken)
local guildId<const> = Config.GuildId
local resourceName<const> = GetCurrentResourceName()


local debug<const> = function(...)
    if not Config.Debug then return end
    local time = os.date("%m/%d/%Y %I:%M:%S %p")
    local color = '^4'
    return print(string.format('%s[%s]^3[%s]^7 %s', color, resourceName, time, string.format(...)))
end

--- Return the Discord ID of a player
---@param user string
---@return string
local returnDiscordId<const> = function(user)
    local identifier<const> = GetPlayerIdentifierByType(user, 'discord')
    
    return identifier and identifier:gsub('discord:', '') or nil
end

exports('returnDiscordId', returnDiscordId)

local discordRequest<const> = function(method, endpoint, data, cb)
    local returned = {}
    local received <const> = promise.new()

    PerformHttpRequest(('https://discordapp.com/api/%s'):format(endpoint), function(error, result, headers)
        returned.error = error
        returned.result = result
        returned.headers = headers

        if received then
            received:resolve()
        end
    end, method, type(data) == 'string' and data or '', {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = formattedToken
    })

    Citizen.Await(received)

    return returned
end

local fetchUserData<const> = function(discordId)

    local defaultData = { 
        username = 'Not Found',
        avatar = Config.DefaultAvatar,
        banner = Config.DefaultBanner,
        roles = {}
    }

    local data = discordRequest('GET', ('guilds/%s/members/%s'):format(guildId, discordId), {})

    if data.error ~= 200 then debug('Error fetching user data: %s', data.error) return defaultData end

    local result = json.decode(data.result)

    if not result or (result and not result.roles) then return defaultData end

    print(json.encode(result, {indent = true}))

    return {
        username = result.user.username,
        avatar = result.user.avatar and ('https://cdn.discordapp.com/avatars/%s/%s.gif'):format(result.user.id, result.user.avatar) or result.user.avatar and ('https://cdn.discordapp.com/avatars/%s/%s.png'):format(result.user.id, result.user.avatar) or Config.DefaultAvatar,
        banner = result.user.banner and ('https://cdn.discordapp.com/banners/%s/%s.gif'):format(result.user.id, result.user.banner) or result.user.banner and ('https://cdn.discordapp.com/banners/%s/%s.png'):format(result.user.id, result.user.banner) or Config.DefaultBanner,
        roles = result.roles or {},
        discriminator = result.user.discriminator or '0000'
    }
end


--- Get the user's Discord username
---@param discordId string
---@param discriminator boolean
---@return string
local getDiscordName<const> = function(discordId, discriminator)
    local user = CACHED.USERS[discordId]

    return user and (user.username .. (discriminator and ('#%s'):format(user.discriminator) or '')) or 'Not Found'
end

--- Get the user's Discord roles
---@param discordId string
---@return table
local getDiscordRoles<const> = function(discordId)
    local user = CACHED.USERS[discordId]

    debug(json.encode(user))

    return user and user.roles or {}
end


--- Check if a user has a specific role
---@param discordId string
---@param role string
local doesUserHaveRole<const> = function(discordId, role)
    local roles = getDiscordRoles(discordId)

    for _, r in ipairs(roles) do
        if r == role then return true end
    end

    return false
end


--- Check if a user has any of the specified roles
---@param discordId string
---@param roles table
local doesUserHaveAnyRole<const> = function(discordId, roles)
    for _, role in ipairs(roles) do
        if doesUserHaveRole(discordId, role) then return true end
    end

    return false
end

--- Check if a user has all of the specified roles
---@param discordId string
---@param roles table -- The roles to check
local doesUserHaveAllRoles<const> = function(discordId, roles)
    for _, role in ipairs(roles) do
        if not doesUserHaveRole(discordId, role) then return false end
    end

    return true
end

--- Get the user's Discord avatar
---@param discordId string
---@return string
local getDiscordAvatar<const> = function(discordId)
    local user = CACHED.USERS[discordId]

    return user and user.avatar or Config.DefaultAvatar
end

--- Get the user's Discord banner
---@param discordId string
---@return string
local getDiscordBanner<const> = function(discordId)
    local user = CACHED.USERS[discordId]

    return user and user.banner or Config.DefaultBanner
end

exports('getDiscordName', getDiscordName)
exports('getDiscordAvatar', getDiscordAvatar)
exports('getDiscordBanner', getDiscordBanner)
exports('getDiscordRoles', getDiscordRoles)
exports('doesUserHaveRole', doesUserHaveRole)
exports('doesUserHaveAnyRole', doesUserHaveAnyRole)
exports('doesUserHaveAllRoles', doesUserHaveAllRoles)




--- Initialize a player when they join the server
local initPlayer<const> = function()
    local serverId<const> = source

    debug('Player %s has joined the server.', serverId)

    local discordId<const> = returnDiscordId(serverId)

    if not discordId then 
        debug('Player %s does not have a Discord ID, skipping initialization.', serverId)
        debug('(1CACHED.USERS: %s)', json.encode(CACHED.USERS, {indent = true}))

        return 
    end
    
    if CACHED.USERS[discordId] then 
        return debug('User %s has already been initialized.', getDiscordName(serverId, false)) 
    end
    
    local user<const> = fetchUserData(discordId)

    CACHED.USERS[discordId] = user

    debug('User %s (%s) has joined the server.', user.username, discordId)
    debug('(2CACHED.USERS: %s)', json.encode(CACHED.USERS, {indent = true}))

    if Config.AcePermissions.Enabled then 
        for roleId, aceGroup in pairs(Config.AcePermissions.Roles) do
            if doesUserHaveRole(discordId, roleId) then
                debug('User %s (%s) has been added to the ACE group %s.', user.username, discordId, aceGroup)
                ExecuteCommand(('add_principal identifier.discord:%s %s'):format(discordId, aceGroup))
            else
                debug('User %s (%s) has been removed from the ACE group %s.', user.username, discordId, aceGroup)
                ExecuteCommand(('remove_principal identifier.discord:%s %s'):format(discordId, aceGroup))
            end
        end
    end
end

RegisterNetEvent('entity::server::initPlayer', initPlayer)


AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local discordId<const> = returnDiscordId(src)
    if not discordId then 
        if Config.DiscordRequired then
            setKickReason((('[%s] You must link your Discord account to join this server.'):format(resourceName)))
            CancelEvent()
            return
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src<const> = source
    local serverId<const> = src
    local discordId<const> = returnDiscordId(serverId)

    if not CACHED.USERS[discordId] then return end

    debug('User %s (%s) has left the server.', getDiscordName(serverId, false), discordId)

    CACHED.USERS[discordId] = nil
end)

