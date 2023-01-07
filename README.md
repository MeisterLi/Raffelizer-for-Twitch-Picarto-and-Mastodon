Run fun Raffles with your Viewers!
==================================

The Raffelizer is a fun way to hold a Raffle or stage a fight with a single, randomly determined winner on your live stream. Users can enter the Raffle by typing in the Raffle word and are then spawned with their Avatar on the outside of the battlefield. Each of them also gets a random weapon assigned for flavour.

When the streamer presses "start", all spawned Avatars move to the middle and a cartoon-style fight breaks out. One by one, losers are knocked out until only the winner remains!

Quick Video Overview
====================

Have a look at this overview video for a quick explanation of how to use this in your Twitch stream!
[![A video showing the Twitch Flow](https://img.youtube.com/vi/1ALivPQGX3c/0.jpg)](https://www.youtube.com/watch?v=1ALivPQGX3c)


Update: Now with Mastodon Support!
==================================

[![A video showing the Mastodon Functionality](https://img.youtube.com/vi/kbBerSFr9OE/0.jpg)](https://www.youtube.com/watch?v=kbBerSFr9OE)

Added now is support for instant Raffles with a fun animation on Mastodon! Simply select the Mastodon option on the main screen, put in the link to the Toot you made for the Raffle and select the criteria for participation - Everything else will be done on it's own! :)

Note that the Raffelizer will not log into any account to fetch information, so depending on the protection settings of the people that follow you or their instance, it may not be possible to fetch their followers for example!

Picarto usage
=============

If you plan on using this tool with Picarto, please open your Picarto chat, then open the Developer Tools of your browser and go to the "Network" tab.  

Reload the page and filter the results by "Chat". You should see a very long link staring with wss://chat.picarto.tv/chat/token=<token>.  

Copy this link into the Raffelizer after pressing "Picarto". You can then use the Save button to store the url in the settings file afterward.

**Note:** There might be two entries found with this filter. If you click on them, you should see one with several entries and one with none - it's the one showing entries that you need to copy.  

Reset and Run automatically
===========================

To run the game indefinitely, open the Settings on the first screen and check the box next to "Auto-Timer". Also input the time for users to join fights (in Minutes) and time between each fight. Press return on both text boxes!

Custom Background
=================

You can put an image of 1024\*600 resolution into your _%AppData%\\Godot\\app\_userdata\\Raffelizer_ (Windows) or   
_~/.local/share/godot/app\_userdata/Raffelizer (Linux)_  
directory and name it battlefield.png to load a custom background on App start.

To toggle an entirely Magenta-Colored background and flat buttons and input fields, in case you want to overlay the Raffelizer over something using OBS, enable "Transparency Mode" in the settings or toggle it on the fly pressing "Ctrl and T" on your keyboard.

Builds
===========

Pre-Compiled builds can be found on my itch.io:
https://manikobunneh.itch.io/raffelizer-for-twitch-and-picarto

Support
=======

If you'd like to support me, you can either make a donation for the program on itch, or find my Ko-Fi here:

[https://ko-fi.com/meisterlitweet6607](https://ko-fi.com/meisterlitweet6607)
