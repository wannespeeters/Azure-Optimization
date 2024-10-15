# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
(Connect-AzAccount -Identity).context

$Subscriptions = Get-AzSubscription

#Get all the unknown RBAC assignments on each subscription and remove these
foreach ($Sub in $Subscriptions){
	Select-AzSubscription -SubscriptionName $Sub.Name
   
    $OBJTYPE = "Unknown"
    $unknownAssignments = Get-AzRoleAssignment | Where-Object {$_.ObjectType.Equals($OBJTYPE)}

    foreach ($assignment in $unknownAssignments) { 
        Remove-AzRoleAssignment -ObjectId $assignment.ObjectId -RoleDefinitionName $assignment.RoleDefinitionName -Scope $assignment.Scope
        Write-Output "Removed role assignment on scope $($assignment.Scope)" 
    }
}