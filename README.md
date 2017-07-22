# DiscordKiso

[Add this bot to your server!](https://discordapp.com/oauth2/authorize?&client_id=338421678579122186&scope=bot&permissions=0)

## Setup

Type `!setup` to add your server to my database. From there you should set tell me what roles can edit my settings by using `!addrole :role`.

## Stream Alerts

I will always announce everyone in the server when they go live. Just set which channel to announce to by going to that channel and typing `!setlog`.

## Commands

### Administrative

These commands will check to see if the user's role is part of the administrative ones you provided. If none were provided, ANYONE can use these, so be careful!

That being said, if you ever lose control of me, removing me from your server and re-adding me will reinitialize the administrative list.

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

### General Commands

`!avatar :user` - Shows a big version of the avatar of a user  
`!coin`, `!flip` - Flips a coin  
`!pick :options`, `!choose :options` - Chooses from a comma separated list  
`!roll :number` - Rolls dice by number or by `xdy` format  
`!predict :question` - 8ball prediction  
`!smug` - Posts a random smug anime girl  
`!guidance` - Random Dark Souls guidance message  
`!safe :tag` - Posts a random sfw anime image, with or without a tag (Uses Danbooru. See: `!safe help`)

### NSFW Commands

`!dan :tag1 :tag2` - Default command  
`!ecchi :tag1` - Applies `rating:questionable` tag  
`!lewd :tag1` - Applies `rating:explicit` tag  

Danbooru is a anime imageboard. You can search up to two tags with this command or you can leave it blank for something random. For details on tags, see [here](https://danbooru.donmai.us/wiki_pages/43037).

`!doujin :search` - Posts a doujin from a search term from nhentai
