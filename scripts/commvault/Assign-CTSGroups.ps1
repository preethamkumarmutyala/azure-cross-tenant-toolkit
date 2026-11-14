param(
    [Parameter(Mandatory)]
    [string]$ServicePrincipalId,

    [Parameter(Mandatory)]
    [string]$TenantName
)

$AppRoleId = (
    Get-MgServicePrincipal -ServicePrincipalId $ServicePrincipalId
).AppRoles |
Where-Object {
    $_.DisplayName -eq "msiam_access"
} |
Select-Object -ExpandProperty Id

$Groups = @(
"External-All-Tenant-Network-Global-Admins",
"External-Tenant-All-CloudEng-Global-Admins",
"GSO-External-All-Tenant-Global-Admin",
"GSO-External-All-Tenant-Global-Reader",
"GSO-JIT-All-Tenant-Viewer-Azure",
"GSO-JIT-$TenantName-Admin-Azure",
"Network-JIT-$TenantName-Admin-Azure",
"GSO-JIT-CloudSec-$TenantName-PolicyManager-Azure",
"GSO-JIT-TVM-$TenantName-TagManager-Azure"
)

Write-Host ""
Write-Host "Assigning CTS Groups for $TenantName"
Write-Host ""

foreach($GroupName in $Groups)
{
    $Group = Get-MgGroup -All |
        Where-Object {
            $_.DisplayName -eq $GroupName
        } |
        Select-Object -First 1

    if(!$Group)
    {
        Write-Warning "$GroupName not found"
        continue
    }

    $Existing = Get-MgServicePrincipalAppRoleAssignedTo `
        -ServicePrincipalId $ServicePrincipalId |
        Where-Object {
            $_.PrincipalId -eq $Group.Id
        }

    if($Existing)
    {
        Write-Host "Already Assigned: $GroupName"
        continue
    }

    New-MgServicePrincipalAppRoleAssignedTo `
        -ServicePrincipalId $ServicePrincipalId `
        -PrincipalId $Group.Id `
        -ResourceId $ServicePrincipalId `
        -AppRoleId $AppRoleId | Out-Null

    Write-Host "Assigned: $GroupName"
}

$AssignmentCount = (
    Get-MgServicePrincipalAppRoleAssignedTo `
        -ServicePrincipalId $ServicePrincipalId
).Count

Write-Host ""
Write-Host "Final Assignment Count: $AssignmentCount"