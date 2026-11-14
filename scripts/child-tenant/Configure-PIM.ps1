param(
    [Parameter(Mandatory)]
    [string]$TenantId
)

if(-not (Get-MgContext))
{
    Connect-MgGraph `
        -TenantId $TenantId `
        -Scopes RoleManagement.ReadWrite.Directory,Directory.Read.All
}

$GARole = Get-MgRoleManagementDirectoryRoleDefinition `
-Filter "displayName eq 'Global Administrator'"

$Users = Get-Content `
"$PSScriptRoot\..\common\Standard-PIM-Users.json" |
ConvertFrom-Json

$DirectoryUsers = Get-AzADUser

$ExistingAssignments =
Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All

foreach($UserName in $Users.Users)
{
    $User = $DirectoryUsers |
        Where-Object {
            $_.DisplayName -eq $UserName
        } |
        Select-Object -First 1

    if(!$User)
    {
        Write-Warning "$UserName not found"
        continue
    }

    $Existing = $ExistingAssignments |
        Where-Object {
            $_.PrincipalId -eq $User.Id -and
            $_.RoleDefinitionId -eq $GARole.Id
        }

    if($Existing)
    {
        Write-Host "Already Exists: $UserName"
        continue
    }

    try
    {
        $Params = @{
            Action           = "adminAssign"
            PrincipalId      = $User.Id
            RoleDefinitionId = $GARole.Id
            DirectoryScopeId = "/"
            Justification    = "Standard tenant onboarding"

            ScheduleInfo = @{
                StartDateTime = (Get-Date).ToUniversalTime()

                Expiration = @{
                    Type = "NoExpiration"
                }
            }
        }

        New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest `
            -BodyParameter $Params `
            -ErrorAction Stop | Out-Null

        Write-Host "Added: $UserName"
    }
    catch
    {
        Write-Warning "Failed: $UserName"
        Write-Warning $_.Exception.Message
    }
}