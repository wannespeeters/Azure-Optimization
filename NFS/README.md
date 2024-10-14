# --------------------------------------------------------------------------------------------------------------------------------------------------------------- #
# This Powershell/automation script is used to automate the creation of NFS file share snapshots for storage accounts.
# The script will create hourly snapshots for the current day and will clean up the snapshots of the day before while maintaining a daily snapshot for 90 days.
# Changing the daily retention of the script can be done by changing the $oldSnapshotsTime variables to a higher/lower value.
# IMPORTANT, NFS file shares can only make up to 200 snapshots per share, if this limit is exceeded, new snapshots cannot be made.
# --------------------------------------------------------------------------------------------------------------------------------------------------------------- #