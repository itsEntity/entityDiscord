DISCORD_CONFIG = { 
    BotToken = 'YOUR_BOT_TOKEN', -- This is the token of your Discord bot. You can get this by creating a bot on the Discord Developer Portal.
    GuildId = 'YOUR_GUILD_TOKEN', -- This is the ID of your Discord server. You can get this by right clicking on your server icon and clicking "Copy ID".
    DefaultAvatar = 'https://cdn.discordapp.com/embed/avatars/0.png', -- This is the default avatar for users who don't have an avatar set on Discord.
    DefaultBanner = 'https://cdn.discordapp.com/embed/avatars/0.png', -- This is the default banner for users who don't have a banner set on Discord. 
    DiscordRequired = false, -- If set to true, players will be required to link their Discord account to join the server.
    Debug = true, -- If set to true, debug messages will be printed to the server console.


    AcePermissions = { 
        Enabled = false, 
        Roles = { 
            ['132321123231'] = 'group.admin', 
            ['discordRoleID1'] = 'group.moderator', 
            ['discordRoleID2'] = 'group.user'
        } 
    }
}