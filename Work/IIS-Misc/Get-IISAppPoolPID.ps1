<#
.SYNOPSIS
    Lists each AppPool with name and PID

.DESCRIPTION
    Combines the AppPool Name with the Process ID so for all AppPools. Can filter via where-object.

.EXAMPLE
     Get-IISAppPoolPID.ps1

.EXAMPLE
    Get-IISAppPoolPID.ps1 | where-object { $_.PID } | ft -AutoSize

.EXAMPLE
    Get-IISAppPoolPID.ps1 | where-object { $_.State -eq 'Running' } | ft -AutoSize
#>


[CmdletBinding()]
param ()

BEGIN {
    # WebAdministration Module MUST be available
    if (-not ((Get-Module -ListAvailable).Where{ $_.Name -eq "WebAdministration"})) {
        Write-Warning "IIS WebAdministration Module does not seem to be available."
        Return 1
    }
}

PROCESS {
    try {
        Import-Module WebAdministration
        $AppPools = Get-ChildItem IIS:\AppPools
        $AppPools | ForEach-Object {
            $APName = $_.Name
                $ProcID = $null
                $State = "Not Active"
                $Started = $null
            $WP = Get-ChildItem IIS:\AppPools\$APName\WorkerProcesses
            $WP | ForEach-Object {
                $ProcID = $_.ProcessID
                $State = $_.State
                $Started = $_.StartTime
            }
            $Props = @{
                Name = $APName
                State = $State
                Started = $Started
                PID = $ProcID
            }
            New-Object -TypeName psobject -Property $Props
        }
    }
    catch { "Error reading information"; $_ }

}

END {
    # All Done!
}

