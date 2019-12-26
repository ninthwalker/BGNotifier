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


# Coordinates of BG que window. Change these to your own
# See Instructions on the Github page or use the Get-Coords function.

$topleftX     = 1461
$topLeftY     = 241
$bottomRightX = 1979
$bottomRightY = 356

# Screenshot Location to save temporary img to for OCR Scan
$path = "C:\temp\"

# Amount of seconds to wait before scanning for a battleground Queue window.
# Note: this script uses hardly any resources and is very quick at the screenshot/OCR process.
# Keep in mind you have 1.5min to accept the Queue. And this script needs to see the popup, and send the notification.
# Then you have to get off the toilet and make it back to your computer in time. Food for thought.
$delay = 15

# Option to stop BGNotifier once a BG Queue has popped. "Yes" to stop the program, or "No" to keep it running.
$stopOnQueue = "Yes"

# Your Discord Channel Webhook. Put your own here.
$discordWebHook = "https://discordapp.com/api/webhooks/659308 - looks something like this - HRebC2J0GIJP1aDASDlhdajhsdfLIHBUEysJ-fR"


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
    Add-Type -AssemblyName System.Windows.Forms
    $X = [System.Windows.Forms.Cursor]::Position.X
    $Y = [System.Windows.Forms.Cursor]::Position.Y
    Write-Output "X: $X | Y: $Y"
}

# Screenshot function
function Get-BGQueue {

    $bounds   = [Drawing.Rectangle]::FromLTRB($topleftX, $topLeftY, $bottomRightX, $bottomRightY)
    $pic      = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
    $graphics = [Drawing.Graphics]::FromImage($pic)

    $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

    $pic.Save("$path\wowImg.png")

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

# Notification function
function BGNotifier {
    $button_start.Enabled = $False
    $button_stop.Enabled = $True
    $form.MinimizeBox = $False # disable while running since it breaks things
    $label_status.text = "BG Notifier is Running!"
    $label_status.Refresh()
    $script:cancelLoop = $False

    :check Do {
        # check for clicks in the form since we are looping
        for ($i=0; $i -lt $delay; $i++) {

            [System.Windows.Forms.Application]::DoEvents()

            if ($script:cancelLoop) {
                $button_start.Enabled = $True
                $button_stop.Enabled = $False
                $form.MinimizeBox = $True
                $label_status.text = ""
                $label_status.Refresh()
                Break check
            }

            Sleep -Seconds 1
        }

        Get-BGQueue
        $bgAlert = (Get-Ocr $path\wowImg.png).Text
        
    }
    Until (($bgAlert -like "*Alterac*") -or ($bgAlert -like "*Warsong*") -or ($bgAlert -like "*Arathi*"))

    if ($script:cancelLoop) {
        Return
    }

    # Send msg to Discord
    if ($bgAlert -like "*Alterac*") {
        $msg = "Your Alterac Valley Queue has Popped!"
    }
    elseif ($bgAlert -like "*Warsong*") {
        $msg = "Your Warsong Gulch Queue has Popped!"
    }
    elseif ($bgAlert -like "*Arathi*") {
        $msg = "Your Arathi Basin Queue has Popped!"
    }

    $headers = @{
        "Content-Type" = "application/json"
    }

    $body = @{
        content = $msg
    } | convertto-json

    # send msg and update status
    Invoke-RestMethod -Uri $discordWebHook -Method POST -Headers $headers -Body $body

    if ($stopOnQueue -eq "Yes") {
        $label_status.text = "Your Queue Popped!"
        $label_status.Refresh()
        $button_start.Enabled = $True
        $button_stop.Enabled = $False
        $form.MinimizeBox = $True
    }
    elseif ($stopOnQueue -eq "No") {
        BGNotifier
    }

}

# Form section
$form                           = New-Object System.Windows.Forms.Form
$form.Text                      ='BG Notifier'
$form.Width                     = 250
$form.Height                    = 120
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
$button_start.width             = 80
$button_start.height            = 25
$button_start.location          = New-Object System.Drawing.Point(20,15)
$button_start.Font              = 'Microsoft Sans Serif,9,style=Bold'
$button_start.FlatStyle         = "Flat"

# Stop Button
$button_stop                    = New-Object system.Windows.Forms.Button
$button_stop.BackColor          = "#f5a623"
$button_stop.ForeColor          = "#FF0000"
$button_stop.text               = "STOP"
$button_stop.width              = 80
$button_stop.height             = 25
$button_stop.location           = New-Object System.Drawing.Point(130,15)
$button_stop.Font               = 'Microsoft Sans Serif,9,style=Bold'
$button_stop.FlatStyle          = "Flat"
$button_stop.Enabled            = $False

# Status label
$label_status                   = New-Object system.Windows.Forms.Label
$label_status.text              = ""
$label_status.AutoSize          = $True
$label_status.width             = 30
$label_status.height            = 20
$label_status.location          = New-Object System.Drawing.Point(20,50)
$label_status.Font              = 'Microsoft Sans Serif,10,style=Bold'
$label_status.ForeColor         = "#7CFC00"


# add all controls
$form.Controls.AddRange(($button_start,$button_stop,$label_status))

# Button methods
$button_start.Add_Click({BGNotifier})
$button_stop.Add_Click({$script:cancelLoop = $True})

# catch close handle
$form.add_FormClosing({$script:cancelLoop = $True})

# show the forms
$form.ShowDialog()

# close the forms
$form.Dispose()
