# BattlegroundNotifier
Sends a message when your World of Warcraft Battleground Queue has popped.
Currently supports Discord. Possibly more notification methods to come in the future if requested.
Note: This does not interact with the game at any level or in any way.

## Details/Requirements
1. Windows 10
2. Powershell 3.0+ (Comes with WIN10)
3. .Net Framework 3.5+ (Usually already on Windows 10 as well)
4. A World of Warcraft Subscription. (You have to put this on your WIN 10 computer yourself)
5. Probably a little computer/command line know-how. Or a C in Reading Comprehension 101 to follow the below instructions.

## How it works
It's super simple. It takes a screenshot of a specific area of your monitor (Where the BG Queue window pops up).  
It then uses Windows 10 Built-in OCR (Optical Character Recognition) to read the text in that screenshot to see if a BG has popped. If it has, it sends you a message on Discord. Too easy!

## Download Options

**Note:**
Depending on your download method/settings, you may need to 'unblock' the files after downloading them from Github. This is normal behavior for Microsoft Windows to do for files downloaded from the internet.  
`Right click > Properties > Check 'Unblock'`

**Option One** (Recommended)
1. Copy the 'BGNotifier.lnk' shortcut, as well as the BGNotifier.ps1 file to your computer. Place in the same directory.
3. Once Setup is completed, you can double click the shortcut to run the Battleground Notifier.  

**Option Two**
1. Copy the BGNotifier.ps1 file to your desktop.
2. Open a powershell console and navigate to the folder you saved the BGNotifier.ps1 file to.
3. Enter the below command to temporarily set the execution policy:  
  `Set-ExecutionPolicy -Scope Process Bypass`  
  Alternatively, set the execution policy to permanently allow powershell scripts:  
  `Set-ExecutionPolicy -Scope Currentuser Unrestricted`  
4. See Initial Setup section below to configure.
5. once setup is completed, you can launch the script by entering the following command in powershell:  
`.\BGNotifier.ps1`  

## Config/Settings  
Some initial configurations is required before it will work for you.  
If you right click and edit the BGNotifier.ps1 file you will see a section near the top that requires you to enter your own settings.

1. Configure the X,Y Coordinates of your battleGround Que Window  
Everyones monitors are different, so we need to get your coordinate for where your BG Que window pops up.
If you have multiple monitors, the best way to do this is to open your game on the main monitor and a Powershell ISE window on another. 
Press 'CTRL+R' to open the script pane. Then paste the following code into the top window.  

```
Add-Type -AssemblyName System.Windows.Forms
$X = [System.Windows.Forms.Cursor]::Position.X
$Y = [System.Windows.Forms.Cursor]::Position.Y
Write-Output "X: $X | Y: $Y"
```  

Join a BG Queue and wait for the BG Notification window to popup on your game screen. Click once in the PowerShell ISE window to focus that program. Now move your mouse to the top left of the BG Notification Box. Do not click the wow screen at any time! Instead press F5, which will run that code snippet above. It will Give you the X and Y coordinate of your mouse curser. Now move your mouse to the bottom right of the Battleground Notification window and press F5 again to get those coordinates.  

These 4 coordinates are what you will use to enter into the coordinate section in the Powershell script.  
If you can't do this easily with multiple monitors, you may need to play some trial and error with entering in guestimated x and y coordinates until you get a close enough box for where your Battleground Queue window pops up at.

2. Screenshot Path
Set the path to where you would like the temporary screenshot to be saved to. By default it goes to C:\temp\  

3. Screenshot Delay
If you would like to change how often the script scans for the Battleground Queue Window you can enter a different time here in seconds.
Note: this script uses hardly any resources and is very quick at the screenshot/OCR process. Keep in mind you have 1.5min to accept the Queue. And this script needs to see the popup, and send the notification.  
Then you have to get off the toilet and make it back to your computer in time. Food for thought.

4. Discord Webhook URL
Enter in the discord webhook for the channel you would like the notification to go to.  
Discord > Click cogwheel next to a channel to edit it > Webhooks > Create webhook.
See this quick youtube video I found if you need further help. It's very easy. Do not share this Webhook with anyone else.  
[Create Discord Webhook](https://www.youtube.com/watch?v=zxi926qhP7w)


## Screenshots  
Note: Need to add still

![](https://raw.githubusercontent.com/ninthwalker/BattlegroundNotifier/master/screenshots/-.png)  

![](https://raw.githubusercontent.com/ninthwalker/BattlegroundNotifier/master/screenshots/-png)  

![](https://raw.githubusercontent.com/ninthwalker/BattlegroundNotifier/master/screenshots/-.png)  

![](https://raw.githubusercontent.com/ninthwalker/BattlegroundNotifier/master/screenshots/-.png)  

![](https://raw.githubusercontent.com/ninthwalker/BattlegroundNotifier/master/screenshots/-.png)
