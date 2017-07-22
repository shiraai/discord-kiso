# DiscordKiso

[Add this bot to your server!](https://discordapp.com/oauth2/authorize?&client_id=338421678579122186&scope=bot&permissions=0)

## Setup

Type `!setup` to add your server to my database. From there you should set tell me what roles can edit my settings by using `!addrole :role`.

## Stream Alerts

I will always announce everyone in the server when they go live. Just set which channel to announce to by going to that channel and typing `!setlog`.

## Commands

### Administrative

These commands will check to see if the user's role is part of the administrative ones you provided. If none were provided, ANYONE can use these, so be careful!

`!ping`, `!kiso` - Generic ping, outputs debug info to the console  
`!setup` - Initializes your server to the database  
`!addrole :roles` - Adds mentioned roles to allow modification to settings  
`!delrole :roles` - Removes mentioned roles to allow modification to settings  
`!setlog` - Sets the log channel for stream announcements  
`!stoplog` - Completely stops logging for the server  
  
`!addhere user :users` - Bot will @here everytime these users go live  
`!delhere user :users` - Bot will not @here everytime these users go live  
`!addhere role :roles` - Bot will @here everytime users of this role go live  
`!delhere role :roles` - Bot will not @here everytime users of this role go  live

`!add :command ~text` - Adds a custom command with the given text  
`!del :command` - Removes a custom command  
