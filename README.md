# BGNotifier  <img src="https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/mobile2.png">  
Sends a message when your World of Warcraft Battleground Queue has popped.  
Currently supports Discord. Possibly more notification methods to come in the future if requested.  
Note: This does not interact with the game at any level or in any way.  
Note2: This is only for Classic for now. While it is easily modified to work for Retail, the queue's there are not that bad.

## Details/Requirements
1. Windows 10
2. Powershell 3.0+ (Comes with WIN10)
3. .Net Framework 3.5+ (Usually already on Windows 10 as well)
4. A World of Warcraft Subscription. (You have to put this on your WIN 10 computer yourself)
5. A Discord account and Discord app on your phone (Other apps/notifications possible in the future if requested)
6. Probably a little computer/command line know-how. Or a C in Reading Comprehension 101 to follow the below instructions.

## How it works
It's super simple. It takes a screenshot of a specific area of your monitor (Where the BG Queue window pops up).  
It then uses Windows 10 Built-in OCR (Optical Character Recognition) to read the text in that screenshot to see if a BG has popped. If it has, it sends you a message on Discord. Too easy!

## How to use  
Prereq's: WoW Must be running in the foreground of your monitor. Discord App on your computer must *not* be running. (Discord does not send mobile notifications if you are Active in another Discord app =( See Dev post [here](https://twitter.com/discordapp/status/720723876934582272))  
After clicking the shortcut (Download Option One) or Lauching the script from the command line (Download Option Two):  

1. Click 'Start' to begin scanning for BG Queue's and notifying you.
2. Click 'Stop' to halt scanning and notifications.
3. ???
4. Profit!  
  
## Download Options  

**Option One**  
 (Recommended - Easiest to use)

1. Click the 'Clone or Download' link on this page. Then select 'Download Zip'  
2 . You may need to 'unblock' the zip file downloaded. This is normal behavior for Microsoft Windows to do for files downloaded from the internet.  
`Right click > Properties > Check 'Unblock'`
3. Extract the contents of the ZIP file. You only need the 'BGNotifier.lnk' shortcut, and the BGNotifier.ps1 files. Make sure these 2 files are kept in the same directory wherever you move them to.  
4. Once Setup is completed, you can double click the shortcut to run the BG Notifier script.  

**Option Two**  
(For those will some Powershell experience, or if you don't want to use the shortcut method above)
1. Copy the BGNotifier.ps1 file to your computer.
2. Open a powershell console and navigate to the folder you saved the BGNotifier.ps1 file to.
3. Enter the below command to temporarily set the execution policy:  
`Set-ExecutionPolicy -Scope Process Bypass`  
Alternatively, set the execution policy to permanently allow powershell scripts:  
`Set-ExecutionPolicy -Scope Currentuser Unrestricted`  
4. Once setup is completed, you can launch the script by entering the following command in powershell:  
`.\BGNotifier.ps1`  

## Config/Settings  
Some initial configuration is required before it will work for you.  
If you right click and edit the BGNotifier.ps1 file you will see a section near the top that requires you to enter your own settings.

1. **Configure the X,Y Coordinates of your Battleground Queue window**      
Everyones monitors are different, so we need to get your coordinate for where your BG Queue window pops up.  

    1. Open WoW and queue for a BG. Once a BG Queue pops, leave it up and go to step b.  
    1. Launch the BGNotifier app and click the 'Get Coords'.  
    1. The next 2 mouse clicks (approx) that you perform will be recorded into the window for you to get the X,Y coordinates.
Your first click should be on the top left corner of the BG Queue window. Your second click should be on the bottom right of the BG Queue window. If you miss, or mess up, just click 'Exit Coords' in the app, and start again by clicking 'Get Coords'
    1. Keep the BGNotifier app open, write down, memorize (you're smart!), or screenshot the BGNotifier window that has the Top Left and Bottom Right X,Y coordinates. You will need these for the next step.  
    1. Right click on the actual script file. (BGNotifier.ps1) and select Edit. This should open the script for editing. Enter in the coordinates created during step d into their respective sections.

2. **Screenshot Path**  
Set the path to where you would like the temporary screenshot to be saved to.  
By default it goes to C:\temp\  

3. **Screenshot Delay**  
If you would like to change how often the script scans for the Battleground Queue Window you can enter a different time here in seconds.
Note: this script uses hardly any resources and is very quick at the screenshot/OCR process. Keep in mind you have 1.5min to accept the Queue. And this script needs to see the popup, and send the notification.  
Then you have to get off the toilet and make it back to your computer in time. Food for thought.  
Default Value: 20 seconds, which should give you about 1 minute after you get the notification to make it back to accept the Queue.  
  
4. **Stop on Queue**  
'Yes' will stop the script upon BG Queue detection. 'No' will have it continue to scan and must be stopped manually.  
Default is 'Yes'

5. **Discord Webhook URL**  
Enter in the discord webhook for the channel you would like the notification to go to.  
Discord > Click cogwheel next to a channel to edit it > Webhooks > Create webhook.
See this quick video I found on Youtube if you need further help. It's very easy. Do not share this Webhook with anyone else.  
[Create Discord Webhook](https://www.youtube.com/watch?v=zxi926qhP7w)


## Screenshots & Videos  

<img src="https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/mobile.png" width="500">  

![](https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/start.png) ![](https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/stop.png)  

![](https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/coords.png) ![](https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/popped.png)  

![](https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/av.png)  

![](https://raw.githubusercontent.com/ninthwalker/BGNotifier/master/screenshots/files.png)  
