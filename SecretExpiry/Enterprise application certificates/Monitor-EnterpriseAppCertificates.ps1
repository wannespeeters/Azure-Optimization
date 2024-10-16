# Make sure no context is inherited
Disable-AzContextAutosave -Scope Process
# Connect to MG graph with the system assigned managed identity of the account
Connect-MgGraph -Identity -NoWelcome

# Set variables
$Now = Get-Date
$DaysUntilExpiration = 30
$webhookUrl = $YOURWEBHOOKVAR

# Get all Enterprise applications and loop through all certificates, create a ticket per to be expired certificate
$Applications = Get-MgServicePrincipal -all | Where-Object {$_.PasswordCredentials}

# Loop over all applications and set the variable
foreach ($App in $Applications) {
    $Certificates = (Get-MgServicePrincipal -ServicePrincipalId $App.Id | Select-Object PasswordCredentials).PasswordCredentials

    # Loop over all certificates and which will expire within 30 days
    foreach ($Certificate in $Certificates) {
        $RemainingDaysCount = ($Certificate.EndDateTime - $Now).Days

        if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
            $payload = @{}
            $payload = @{
                data = @{
                    essentials = @{
                        alertId = $Certificate.KeyId
                        severity = "Sev2"
                        Name = $App.DisplayName 
                        alertRule = "Enterprise application certificate expiry"
                        monitorCondition = "Fired"
                        description = "The certificate with ID $($Certificate.KeyId) of the enterprise app $($App.DisplayName) will expire in $RemainingDaysCount days. `nEnterpriseAppObjectID: $($App.Id)`nExpiry date: $($Secret.EndDateTime)"
                        configurationItems = @($App.DisplayName)
                    }
                    customProperties = @{
                        # Add custom properties if needed
                    }
                }
            } | ConvertTo-Json -Depth 4
            Invoke-WebRequest -URI $webhookUrl -Method Post -Body $payload -ContentType application/json
            Write-Output: "The certificate with ID $($Certificate.KeyId) of the enterprise app $($App.DisplayName) will expire in $RemainingDaysCount days. `nEnterpriseAppObjectID: $($App.Id)`nExpiry date: $($Secret.EndDateTime)"
        }
    }
}