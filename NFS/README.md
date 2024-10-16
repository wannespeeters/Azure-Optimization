## Create-AzureNfsSnapshot
- This Powershell/automation script is used to automate the creation and deletion of NFS file share snapshots for storage accounts.
- The script will create hourly snapshots for the current day and will clean up the snapshots of the day before while maintaining a daily snapshot for 90 days.
- ![nfs](https://github.com/user-attachments/assets/a89266e6-0bb8-47a3-a4e0-1c45498e72d0)
- Changing the daily retention of the script can be done by changing the $oldSnapshotsTime variables to a higher/lower value.
- IMPORTANT, NFS file shares can only make up to 200 snapshots per share, if this limit is exceeded, new snapshots cannot be made.
