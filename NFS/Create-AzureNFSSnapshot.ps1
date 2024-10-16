# Log into Azure with the managed identity
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
(Connect-AzAccount -Identity).context
$Subscriptions = Get-AzSubscription

$Yesterday = (Get-Date).AddDays(-1)
$Min = $yesterday.AddHours(-0.5)
$Max = $yesterday.AddHours(0.5)

$OldSnapshotTime = (Get-Date).AddDays(-90)

# Loop over all subscriptions
foreach ($Sub in $Subscriptions) {
    Select-AzSubscription -SubscriptionName $Sub.Name
    $NFSstorageAccounts = Get-AzResource -Tag @{ FileShareBackup = "True" } | Where-Object {$_.ResourceType -eq "Microsoft.Storage/storageAccounts"}

    # Loop over all storage accounts where file share snapshot needs to be taken
    foreach ($Straccount in $NFSstorageAccounts) {
        $ResourceGroup = $Straccount.ResourceGroupName
        $StorageAccount = $Straccount.Name
        $Shares = Get-AzRmStorageShare -ResourceGroupName $ResourceGroup -storageAccountName $StorageAccount | Where-Object {$_.EnabledProtocols -eq "NFS"}

        foreach ($Share in $Shares) {
            $Snapshots = Get-AzRmStorageShare -ResourceGroupName $ResourceGroup -storageAccountName $StorageAccount -Filter "startswith(name, $($Share.name))" -IncludeSnapshot | Where-Object {$_.SnapshotTime -le $Max -and $_.SnapshotTime -ge $Min -and $_.SnapshotTime -ne $null}

            # Do not remove daily snapshot at 14
            if($Yesterday.Hour -ne 14) {
                #Remove snapshots from Yesterday
                foreach ($Snapshot in $Snapshots) {
                    Write-Output "Removed hourly snapshot $($Snapshot.SnapshotTime) in $StorageAccount share $($Share.Name)"
                    Remove-AzRmStorageShare -ResourceGroupName $ResourceGroup -storageAccountName $StorageAccount -Name $Share.Name -SnapshotTime $Snapshot.SnapshotTime -Force
                }
            }

            # Remove all snapshots older then 90 days
            $OldSnapshots = Get-AzRmStorageShare -ResourceGroupName $ResourceGroup -storageAccountName $StorageAccount -Filter "startswith(name, $($Share.name))" -IncludeSnapshot | Where-Object {$_.SnapshotTime -le $OldSnapshotTime -and $_.SnapshotTime -ne $null}

            foreach ($OldSnapshot in $OldSnapshots) {
                Remove-AzRmStorageShare -ResourceGroupName $ResourceGroup -storageAccountName $StorageAccount -Name $Share.Name -SnapshotTime $OldSnapshot.SnapshotTime -Force
                Write-Output "Removed snapshot $($Snapshot.SnapshotTime) in $($StorageAccount.name) share $($Share.Name)"
            }

            Write-Output "Creating an hourly snapshot for $StorageAccount share $($Share.Name)"
            New-AzRmStorageShare -ResourceGroupName $ResourceGroup -storageAccountName $StorageAccount -Name $Share.Name -Snapshot
        }
    }
}