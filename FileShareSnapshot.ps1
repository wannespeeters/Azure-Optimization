# Log into Azure with the managed identity
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
$Subscriptions = Get-AzSubscription

$yesterday = (Get-Date).AddDays(-1)
$min = $yesterday.AddHours(-0.5)
$max = $yesterday.AddHours(0.5)

$oldSnapshotsTime = (Get-Date).AddDays(-90)

# Loop over all subscriptions
foreach ($sub in $Subscriptions){
	Select-AzSubscription -SubscriptionName $sub.Name

    $NFSstorageAccounts = Get-AzResource -Tag @{ FileShareBackup = "True" } | where {$_.ResourceType -eq "Microsoft.Storage/storageAccounts"}

    # Loop over all storage accounts where file share snapshot needs to be taken

    foreach ($straccount in $NFSstorageAccounts) {
        $resourceGroup = $straccount.ResourceGroupName
        $storageAccount = $straccount.Name
        $shares = Get-AzRmStorageShare -ResourceGroupName $resourceGroup -StorageAccountName $storageAccount | where {$_.EnabledProtocols -eq "NFS"}

        foreach ($share in $shares) {
            $snapshots = Get-AzRmStorageShare -ResourceGroupName $resourceGroup -StorageAccountName $storageAccount -Filter "startswith(name, $($share.name))" -IncludeSnapshot | where {$_.SnapshotTime -le $max -and $_.SnapshotTime -ge $min -and $_.SnapshotTime -ne $null}

            # Do not remove daily snapshot at 14
            if($yesterday.Hour -ne 14) {
                #Remove snapshots from Yesterday
                foreach ($snapshot in $snapshots) {
                Remove-AzRmStorageShare -ResourceGroupName $resourceGroup -StorageAccountName $storageAccount -Name $share.Name -SnapshotTime $snapshot.SnapshotTime -Force
                $snapshot
                }
            }

            # Remove all snapshots older then 90 days
            $oldSnapshots = Get-AzRmStorageShare -ResourceGroupName $resourceGroup -StorageAccountName $storageAccount -Filter "startswith(name, $($share.name))" -IncludeSnapshot | where {$_.SnapshotTime -le $oldSnapshotsTime -and $_.SnapshotTime -ne $null}

            foreach ($oldSnapshot in $oldSnapshots) {
                Remove-AzRmStorageShare -ResourceGroupName $resourceGroup -StorageAccountName $storageAccount -Name $share.Name -SnapshotTime $oldSnapshot.SnapshotTime -Force
                $oldSnapshot
            }

            Write-Host "Creating an hourly snapshot of share"$share.Name
            New-AzRmStorageShare -ResourceGroupName $resourceGroup -StorageAccountName $storageAccount -Name $share.Name -Snapshot
        }
    }
}
