#####################################################################
# Name: BGNotifier                                                  #
# Desc: Notifies you if a WoW Battleground Queue has popped.        #
# Author: Ninthwalker                                               #
# Instructions: https://github.com/ninthwalker/BGNotifier           #
# Date: 25DEC2019 *Merry Christmas!*                                #
# Version: 1.0                                                      #
#####################################################################

using namespace Windows.Storage
using namespace Windows.Graphics.Imaging

##########################################
### CHANGE THESE SETTINGS TO YOUR OWN! ###
##########################################


### REQUIRED SETTINGS ###
#########################

# One or more notifiaction apps are required. One or All of them can be used at the same time.
# Set the notification app you want to use to '$True' to enable it or '$False' to disable it.
# Then enter your webhook or API type tokens for the notification type you want to use.
# All Notifications are set to $False by default.

## DISCORD ##
$discord = $False
# Your Discord Channel Webhook. Put your own here.
$discordWebHook = "https://discordapp.com/api/webhooks/4593 - EXAMPLE - EVn24sRzpn5KspJHRebCkldhsklrh2378rUIPG8DWgUEtQpEunzGn7ysJ-rT"

## TELEGRAM ##
$telegram = $False
# Get the Token by creating a bot by messaging @BotFather
$telegramBotToken = "96479117:BAH0 - EXAMPLE - yzTvrc6wUKLHKGYUyu34hm2zOgbQDBMu4"
# Get the ChatID by messaging your bot you created, or making your own group with the bot and messaging the group. Then get the ChatID for that conversation with the below step.
# Then go to this url replacing <telegramBotToken> with your own Bots token and look for the chatID to use. https://api.telegram.org/bot<telegramBotToken>/getUpdates
$telegramChatID =  "-371-EXAMPLE-556032"

## ALEXA NOTIFY ME SKILL ##
$alexa = $False
# Enter in the super long access code that the skill emailed you when you set it up in Alexa"
$alexaAccessCode = "amzn1.ask.account.AEHQ4KJGYGIZ3ZZ - EXAMPLE - LMCMBLAHGKJHLIUHPIUHHTDOUDU567L72OXKPXXLVI568EJJVIHYO2DXGMPXPWZDLJKH678UFUYFJUHLIUG45684679GN2QQ7X23MGMHGGIAJSYG4U2SJIWUF3R5FUPDNPA5I"


### OPTIONAL ADVANCED SETTINGS ###
##################################

# Coordinates of BG que window. Change these to your own if you want to customize the area of the screenshot.
# Default settings are to screenshot the top middle of your wow window which should be good for most people, but not all
# See Instructions on the Github page or use the 'Get Coords' within the app to find the area you want to scan for the BG Queue window.
# Change '$useMyOwnCoordinates' to "Yes" and set the coordinates to use your own.
$useMyOwnCoordinates = "No"
$topleftX     = 1461
$topLeftY     = 241
$bottomRightX = 1979
$bottomRightY = 356

# Screenshot Location to save temporary img to for OCR Scan. Change if you want it somewhere else.
$path = "C:\temp\"

# Amount of seconds to wait before scanning for a battleground Queue window.
# Note: this script uses hardly any resources and is very quick at the screenshot/OCR process.
# Keep in mind you have 1.5min to accept the Queue. And this script needs to see the popup, and send the notification.
# Then you have to get off the toilet and make it back to your computer in time. Food for thought.
$delay = 20

# Option to stop BGNotifier once a BG Queue has popped. "Yes" to stop the program, or "No" to keep it running.
# Default is 'Yes', stop scanning after it detects a BG Queue pop.
$stopOnQueue = "Yes"


#########################################
### DO NOT MODIFY ANYTHING BELOW THIS ###
#########################################

# Screenshot method
Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Add the WinRT assembly, and load the appropriate WinRT types
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile,                Windows.Storage,         ContentType = WindowsRuntime]
$null = [Windows.Media.Ocr.OcrEngine,                Windows.Foundation,      ContentType = WindowsRuntime]
$null = [Windows.Foundation.IAsyncOperation`1,       Windows.Foundation,      ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.SoftwareBitmap,    Windows.Foundation,      ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.RandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]

# used to find the BG queue popup location coordinates on  your monitor
function Get-Coords {

    $form.TopMost = $True
    $script:label_coords_text.Enabled = $False
    $script:label_coords_text.Visible = $False
    $button_start.Visible = $False
    $label_status.Text = ""
    $label_status.Refresh()
    $script:label_coords1.Text = ""
    $script:label_coords1.Refresh()
    $script:label_coords2.Text = ""
    $script:label_coords2.Refresh()
    $script:label_coords1.Visible = $True
    $script:label_coords2.Visible = $True
    $script:label_coords_text2.Visible = $True
    $script:label_coords_text2.Enabled = $True
    $script:cancelLoop = $False
    $count = 1

    :coord While( $true ) {
        
        If( (([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift)) -and ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftCtrl))) -or ($script:cancelLoop) -or ($count -ge 3)) { 
            Break
        }
        If( [System.Windows.Forms.UserControl]::MouseButtons -ne "None" ) { 
          While( [System.Windows.Forms.UserControl]::MouseButtons -ne "None" ) {
            Start-Sleep -Milliseconds 100 # Wait for the MOUSE UP event
            [System.Windows.Forms.Application]::DoEvents()
          }
        
            $mp = [Windows.Forms.Cursor]::Position

            if ($count -eq 1) {
                $script:label_coords1.Text = "Top left: $($mp.ToString().Replace('{','').Replace('}',''))" 
                $script:label_coords1.Refresh()
                $count++
            }
            elseif ($count -eq 2) {
                $script:label_coords2.Text = "Bottom Right: $($mp.ToString().Replace('{','').Replace('}',''))"
                $script:label_coords2.Refresh()
                $count++
            }
            if ($count -ge 3) {
                Break coord
            }
            
            
        }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
        

    }
    #[System.Windows.Forms.Application]::DoEvents()
    if (($script:cancelLoop) -or ($count -ge 3)) {
        Return
    }
    

}

# Screenshot function
function Get-BGQueue {

    $bounds   = [Drawing.Rectangle]::FromLTRB($topleftX, $topLeftY, $bottomRightX, $bottomRightY)
    $pic      = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
    $graphics = [Drawing.Graphics]::FromImage($pic)

    $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

    $pic.Save("$path\BGNotifier_Img.png")

    $graphics.Dispose()
    $pic.Dispose()

}

# OCR Scan Function
function Get-Ocr {

# Takes a path to an image file, with some text on it.
# Runs Windows 10 OCR against the image.
# Returns an [OcrResult], hopefully with a .Text property containing the text
# OCR part of the script from: https://github.com/HumanEquivalentUnit/PowerShell-Misc/blob/master/Get-Win10OcrTextFromImage.ps1


    [CmdletBinding()]
    Param
    (
        # Path to an image file
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true, 
                    Position=0,
                    HelpMessage='Path to an image file, to run OCR on')]
        [ValidateNotNullOrEmpty()]
        $Path
    )

    Begin {
        
    
    
        # [Windows.Media.Ocr.OcrEngine]::AvailableRecognizerLanguages
        $ocrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
    

        # PowerShell doesn't have built-in support for Async operations, 
        # but all the WinRT methods are Async.
        # This function wraps a way to call those methods, and wait for their results.
        $getAwaiterBaseMethod = [WindowsRuntimeSystemExtensions].GetMember('GetAwaiter').
                                    Where({
                                            $PSItem.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
                                        }, 'First')[0]

        Function Await {
            param($AsyncTask, $ResultType)

            $getAwaiterBaseMethod.
                MakeGenericMethod($ResultType).
                Invoke($null, @($AsyncTask)).
                GetResult()
        }
    }

    Process
    {
        foreach ($p in $Path)
        {
      
            # From MSDN, the necessary steps to load an image are:
            # Call the OpenAsync method of the StorageFile object to get a random access stream containing the image data.
            # Call the static method BitmapDecoder.CreateAsync to get an instance of the BitmapDecoder class for the specified stream. 
            # Call GetSoftwareBitmapAsync to get a SoftwareBitmap object containing the image.
            #
            # https://docs.microsoft.com/en-us/windows/uwp/audio-video-camera/imaging#save-a-softwarebitmap-to-a-file-with-bitmapencoder

            # .Net method needs a full path, or at least might not have the same relative path root as PowerShell
            $p = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p)
        
            $params = @{ 
                AsyncTask  = [StorageFile]::GetFileFromPathAsync($p)
                ResultType = [StorageFile]
            }
            $storageFile = Await @params


            $params = @{ 
                AsyncTask  = $storageFile.OpenAsync([FileAccessMode]::Read)
                ResultType = [Streams.IRandomAccessStream]
            }
            $fileStream = Await @params


            $params = @{
                AsyncTask  = [BitmapDecoder]::CreateAsync($fileStream)
                ResultType = [BitmapDecoder]
            }
            $bitmapDecoder = Await @params


            $params = @{ 
                AsyncTask = $bitmapDecoder.GetSoftwareBitmapAsync()
                ResultType = [SoftwareBitmap]
            }
            $softwareBitmap = Await @params

            # Run the OCR
            Await $ocrEngine.RecognizeAsync($softwareBitmap) ([Windows.Media.Ocr.OcrResult])

        }
    }
}

# get window and sizes function
Function Get-Window {
    <#
        .NOTES
            Name: Get-Window
            Author: Boe Prox
    #>
    [OutputType('System.Automation.WindowInfo')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipelineByPropertyName=$True)]
        $ProcessName
    )
    Begin {
        Try{
            [void][Window]
        } Catch {
        Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
        }
    }
    Process {        
        Get-Process -Name $ProcessName | ForEach {
            $Handle = $_.MainWindowHandle
            $Rectangle = New-Object RECT
            $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
            If ($Return) {
                $Height = $Rectangle.Bottom - $Rectangle.Top
                $Width = $Rectangle.Right - $Rectangle.Left
                $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
                $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
                If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
                    Write-Warning "Window is minimized! Coordinates will not be accurate."
                }
                $Object = [pscustomobject]@{
                    ProcessName = $ProcessName
                    Size = $Size
                    TopLeft = $TopLeft
                    BottomRight = $BottomRight
                }
                $Object.PSTypeNames.insert(0,'System.Automation.WindowInfo')
                $Object
            }
        }
    }
}

# default screenshot area if no coordinates specified in the above user section
if ($useMyOwnCoordinates -eq "No") {
    $window = Get-Process | ? {$_.MainWindowTitle -like "World of Warcraft"} | Get-Window | select -First 1
    $topleftX = [math]::floor($window.BottomRight.x / 3)
    $topLeftY = 0
    $bottomRightX = [math]::floor($topLeftX * 2)
    $bottomRightY = [math]::floor($window.BottomRight.y / 3)
}


# Notification function
function BGNotifier {
    $button_start.Enabled = $False
    $button_start.Visible = $False
    $button_stop.Enabled = $True
    $button_stop.Visible = $True
    $form.MinimizeBox = $False # disable while running since it breaks things
    $script:label_coords_text.Visible = $False
    $label_help.Visible = $False
    $label_status.ForeColor = "#7CFC00"
    $label_status.text = "BG Notifier is Running!"
    $label_status.Refresh()
    $script:cancelLoop = $False

    :check Do {
        # check for clicks in the form since we are looping
        for ($i=0; $i -lt $delay; $i++) {

            [System.Windows.Forms.Application]::DoEvents()

            if ($script:cancelLoop) {
                $button_start.Enabled = $True
                $button_start.Visible = $True
                $button_stop.Enabled = $False
                $button_stop.Visible = $False
                $form.MinimizeBox = $True
                $label_status.text = ""
                $label_status.Refresh()
                $script:label_coords_text.Visible = $True
                $label_help.Visible = $True
                Break check
            }

            Sleep -Seconds 1
        }

        Get-BGQueue
        $bgAlert = (Get-Ocr $path\BGNotifier_Img.png).Text
        
    }
    Until (($bgAlert -like "*Alterac*") -or ($bgAlert -like "*Warsong*") -or ($bgAlert -like "*Arathi*"))

    if ($script:cancelLoop) {
        Return
    }

    # set messages
    if ($bgAlert -like "*Alterac*") {
        $msg = "Your Alterac Valley Queue has Popped!"
    }
    elseif ($bgAlert -like "*Warsong*") {
        $msg = "Your Warsong Gulch Queue has Popped!"
    }
    elseif ($bgAlert -like "*Arathi*") {
        $msg = "Your Arathi Basin Queue has Popped!"
    }

    # msg Discord
    if ($discord) {

        $discordHeaders = @{
            "Content-Type" = "application/json"
        }

        $discordBody = @{
            content = $msg
        } | convertto-json

        Invoke-RestMethod -Uri $discordWebHook -Method POST -Headers $discordHeaders -Body $discordBody
    }

    # msg Telegram
    if ($telegram) {
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$($telegramBotToken)/sendMessage?chat_id=$($telegramChatID)&text=$($msg)"
    }

    # msg Alexa
    if ($alexa) {
        $alexaBody = @{
            notification = $msg
            accessCode = $alexaAccessCode
        } | ConvertTo-Json

        Invoke-RestMethod https://api.notifymyecho.com/v1/NotifyMe -Method POST -Body $alexaBody
    }

    if ($stopOnQueue -eq "Yes") {
        $label_status.ForeColor = "#FFFF00"
        $label_status.text = "Your Queue Popped!"
        $label_status.Refresh()
        $button_stop.Enabled = $False
        $button_stop.Visible = $False
        $button_start.Enabled = $True
        $button_start.Visible = $True
        $script:label_coords_text.Visible = $True
        $label_help.Visible = $True
        $form.MinimizeBox = $True
    }
    elseif ($stopOnQueue -eq "No") {
        BGNotifier
    }

}

# Form section
$form                           = New-Object System.Windows.Forms.Form
$form.Text                      ='BGNotifier'
$form.Width                     = 250
$form.Height                    = 130
$form.AutoSize                  = $True
$form.MaximizeBox               = $False
$form.BackColor                 = "#4a4a4a"
$form.TopMost                   = $False
$form.StartPosition             = 'CenterScreen'
$form.FormBorderStyle           = "FixedDialog"

# Start Button
$button_start                   = New-Object system.Windows.Forms.Button
$button_start.BackColor         = "#f5a623"
$button_start.text              = "START"
$button_start.width             = 120
$button_start.height            = 50
$button_start.location          = New-Object System.Drawing.Point(62,15)
$button_start.Font              = 'Microsoft Sans Serif,9,style=Bold'
$button_start.FlatStyle         = "Flat"

# Stop Button
$button_stop                    = New-Object system.Windows.Forms.Button
$button_stop.BackColor          = "#f5a623"
$button_stop.ForeColor          = "#FF0000"
$button_stop.text               = "STOP"
$button_stop.width              = 120
$button_stop.height             = 50
$button_stop.location           = New-Object System.Drawing.Point(62,15)
$button_stop.Font               = 'Microsoft Sans Serif,9,style=Bold'
$button_stop.FlatStyle          = "Flat"
$button_stop.Enabled            = $False
$button_stop.Visible            = $False

# Status label
$label_status                   = New-Object system.Windows.Forms.Label
$label_status.text              = ""
$label_status.AutoSize          = $True
$label_status.width             = 30
$label_status.height            = 20
$label_status.location          = New-Object System.Drawing.Point(60,75)
$label_status.Font              = 'Microsoft Sans Serif,10,style=Bold'
$label_status.ForeColor         = "#7CFC00"

# Coords label text
$script:label_coords_text            = New-Object system.Windows.Forms.LinkLabel
$script:label_coords_text.text       = "Get Coords"
$script:label_coords_text.AutoSize   = $True
$script:label_coords_text.width      = 30
$script:label_coords_text.height     = 20
$script:label_coords_text.location   = New-Object System.Drawing.Point(5,100)
$script:label_coords_text.Font       = 'Microsoft Sans Serif,9,'
$script:label_coords_text.ForeColor  = "#00ff00"
$script:label_coords_text.LinkColor  = "#f5a623"
$script:label_coords_text.ActiveLinkColor = "#f5a623"
$script:label_coords_text.add_Click({Get-Coords})

# Coords label text exit
$script:label_coords_text2            = New-Object system.Windows.Forms.LinkLabel
$script:label_coords_text2.text       = "Exit Coords"
$script:label_coords_text2.AutoSize   = $True
$script:label_coords_text2.width      = 30
$script:label_coords_text2.height     = 20
$script:label_coords_text2.location   = New-Object System.Drawing.Point(5,100)
$script:label_coords_text2.Font       = 'Microsoft Sans Serif,9,'
$script:label_coords_text2.ForeColor  = "#00ff00"
$script:label_coords_text2.LinkColor  = "#f5a623"
$script:label_coords_text2.ActiveLinkColor = "#f5a623"
$script:label_coords_text2.Visible    = $False
$script:label_coords_text2.add_Click({
    $script:cancelLoop = $True
    $script:label_coords1.Visible = $False
    $script:label_coords2.Visible = $False
    $button_start.Visible = $True
    $script:label_coords1.Text = ""
    $script:label_coords1.Refresh()
    $script:label_coords2.Text = ""
    $script:label_coords2.Refresh()
    $script:label_coords_text2.Visible = $False
    $script:label_coords_text.Visible = $True
    $script:label_coords_text.Enabled = $True
    $script:label_coords_text2.Enabled = $False
    $form.TopMost = $False
})

# Coords label top left
$script:label_coords1            = New-Object system.Windows.Forms.Label
$script:label_coords1.Text       = ""
$script:label_coords1.AutoSize   = $True
$script:label_coords1.width      = 30
$script:label_coords1.height     = 20
$script:label_coords1.location   = New-Object System.Drawing.Point(10,15)
$script:label_coords1.Font       = 'Microsoft Sans Serif,10,style=Bold'
$script:label_coords1.ForeColor  = "#f5a623"

# Coords label bottom right
$script:label_coords2            = New-Object system.Windows.Forms.Label
$script:label_coords2.Text       = ""
$script:label_coords2.AutoSize   = $True
$script:label_coords2.width      = 30
$script:label_coords2.height     = 20
$script:label_coords2.location   = New-Object System.Drawing.Point(10,40)
$script:label_coords2.Font       = 'Microsoft Sans Serif,10,style=Bold'
$script:label_coords2.ForeColor  = "#f5a623"

# Help link
$label_help                     = New-Object system.Windows.Forms.LinkLabel
$label_help.text                = "Help"
$label_help.AutoSize            = $true
$label_help.width               = 70
$label_help.height              = 20
$label_help.location            = New-Object System.Drawing.Point(210,100)
$label_help.Font                = 'Microsoft Sans Serif,9'
$label_help.ForeColor           = "#00ff00"
$label_help.LinkColor           = "#f5a623"
$label_help.ActiveLinkColor     = "#f5a623"
$label_help.add_Click({[system.Diagnostics.Process]::start("http://github.com/ninthwalker/BGNotifier")})

# add all controls
$form.Controls.AddRange(($button_start,$button_stop,$label_status,$script:label_coords_text,$script:label_coords_text2,$script:label_coords1,$script:label_coords2,$label_help))

# Button methods
$button_start.Add_Click({BGNotifier})
$button_stop.Add_Click({
    if (Test-Path $path\BGNotifier_Img.png) {
        Remove-Item $path\BGNotifier_Img.png -Force -Confirm:$False
    }
    $script:cancelLoop = $True
})

# catch close handle
$form.add_FormClosing({
    if (Test-Path $path\BGNotifier_Img.png) {
        Remove-Item $path\BGNotifier_Img.png -Force -Confirm:$False
    }
    $script:cancelLoop = $True
})

# show the forms
$form.ShowDialog()

# close the forms
$form.Dispose()
