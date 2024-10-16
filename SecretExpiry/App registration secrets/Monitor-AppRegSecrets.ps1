# Make sure no context is inherited
Disable-AzContextAutosave -Scope Process
# Connect to MG graph with the system assigned managed identity of the account
Connect-MgGraph -Identity -NoWelcome

# Set variables
$Now = Get-Date
$DaysUntilExpiration = 30
$WebhookUrl = $YOURWEBHOOKVAR

# Get all app registrations and loop through all secrets and certificates, create an omnitracker ticket per secret/certificate
$Applications = Get-MgApplication -all | Where-Object {$_.PasswordCredentials -and $_.Tags -notcontains "noMonitor"}

# Loop over all applications and set the variables
foreach ($App in $Applications) {
    $Secrets = (Get-MgApplication -ApplicationId $App.Id | Select-Object PasswordCredentials).PasswordCredentials

    #Loop over all found Secrets and checks which ones will expire within 30 days
    foreach ($Secret in $Secrets) {
        $RemainingDaysCount = ($Secret.EndDateTime - $Now).Days

        if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
            #Exclude CWAP_Authsecret entry's from monitoring rule
            if ([string]::IsNullOrEmpty($Secret.CustomKeyIdentifier) -or [System.Text.Encoding]::UTF8.GetString($Secret.CustomKeyIdentifier) -ne "CWAP_AuthSecret") {

                $Payload = @{}
                $Payload = @{
                    data = @{
                        essentials = @{
                            alertId = $Secret.KeyId
                            severity = "Sev2"
                            Name = $App.DisplayName
                            alertRule = "App registration secret expiry"
                            monitorCondition = "Fired"
                            description = "The secret with ID $($Secret.KeyId) of the app registration $($App.DisplayName) will expire in $RemainingDaysCount days. `nAppregObjectID: $($App.Id)`nExpiry date: $($Secret.EndDateTime)"
                            configurationItems = @($App.DisplayName)
                        }
                        customProperties = @{
                            # Add custom properties if needed
                        }
                    }
                } | ConvertTo-Json -Depth 4
                Invoke-WebRequest -URI $WebhookUrl -Method Post -Body $Payload -ContentType application/json
                Write-Output: "The secret with ID $($Secret.KeyId) of the app registration $($App.DisplayName) will expire in $RemainingDaysCount days. `nAppregObjectID: $($App.Id)`nExpiry date: $($Secret.EndDateTime)"
            }
        }
    }
}