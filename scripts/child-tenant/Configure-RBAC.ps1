param(
    [Parameter(Mandatory)]
    [string]$TenantName,

    [Parameter(Mandatory)]
    [string]$ManagementGroupId
)

$Scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"

Write-Host ""
Write-Host "Configuring RBAC for $TenantName"
Write-Host ""

$AdminGroup     = Get-AzADGroup -DisplayName "GSO-JIT-$TenantName-Admin-Azure"
$NetworkGroup   = Get-AzADGroup -DisplayName "Network-JIT-$TenantName-Admin-Azure"
$CloudSecGroup  = Get-AzADGroup -DisplayName "GSO-JIT-CloudSec-$TenantName-PolicyManager-Azure"
$TVMGroup       = Get-AzADGroup -DisplayName "GSO-JIT-TVM-$TenantName-TagManager-Azure"
$ViewerGroup    = Get-AzADGroup -DisplayName "GSO-JIT-All-Tenant-Viewer-Azure"

if(!$AdminGroup)    { throw "Admin group not found" }
if(!$NetworkGroup)  { throw "Network group not found" }
if(!$CloudSecGroup) { throw "CloudSec group not found" }
if(!$TVMGroup)      { throw "TVM group not found" }
if(!$ViewerGroup)   { throw "Viewer group not found" }

function Add-RoleIfMissing {
    param(
        [string]$ObjectId,
        [string]$RoleName
    )

    $Existing = Get-AzRoleAssignment `
        -Scope $Scope `
        -ObjectId $ObjectId `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.RoleDefinitionName -eq $RoleName
        }

    if($Existing)
    {
        Write-Host "Already Exists: $RoleName"
        return
    }

    New-AzRoleAssignment `
        -ObjectId $ObjectId `
        -RoleDefinitionName $RoleName `
        -Scope $Scope | Out-Null

    Write-Host "Added: $RoleName"
}

Add-RoleIfMissing $AdminGroup.Id "Owner"
Add-RoleIfMissing $NetworkGroup.Id "Owner"

Add-RoleIfMissing $CloudSecGroup.Id "Reader"
Add-RoleIfMissing $CloudSecGroup.Id "Resource Policy Contributor"

Add-RoleIfMissing $TVMGroup.Id "Reader"
Add-RoleIfMissing $TVMGroup.Id "Tag Contributor"

Add-RoleIfMissing $ViewerGroup.Id "Reader"
Add-RoleIfMissing $ViewerGroup.Id "Security Reader"

Write-Host ""
Write-Host "RBAC configuration completed."