<#
.SYNOPSIS
    Starts Windows Explorer here or in specified path

.DESCRIPTION
    Starts an instance of Windows Explorer (the file one, not the internet one) in the current folder
    or in a specified location. Can be used with alternate credentials (a la 'run as').

.PARAMETER Path
    By default, the current location. Can be any valid path on the system (and some invalid ones)

.PARAMETER RunAs
    This will prompt for username and password to 'Run As'

.EXAMPLE
     Start-ExplorerHere.ps1

     Starts explorer in the current folder

.EXAMPLE
     Start-ExplorerHere.ps1 -path C:\Windows

     Starts explorer in the C:\Windows folder

.EXAMPLE
     Start-ExplorerHere.ps1 -path C:\Windows\readme.txt

     Starts explorer in the C:\Windows folder (it ignores the file portion)

.EXAMPLE
     Start-ExplorerHere.ps1 -RunAs

     Starts explorer in the current folder, prompting for username and password

.EXAMPLE
     Start-ExplorerHere.ps1 -Admin

     Starts explorer in the current folder as admin (with UAC prompt if enabled)
#>


[CmdletBinding()]
param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true,HelpMessage="Enter a valid directory path")]
    [Alias('Folder', 'Directory', 'Dir', 'Location')]
    [string[]] $Path = $PWD,
    [Parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage="Enter a valid username")]
    [Alias('As', 'User', 'Alternate')]
    [switch] $RunAs = $false,
    [Parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage="Enter a valid username")]
    [Alias('Admin')]
    [switch] $AsAdmin = $false
)

BEGIN { }

PROCESS {
    foreach ($dir in $Path) {
        [bool] $DoIt = $true
        Switch ($dir) {
            # Is a normal directory
            { test-path $_ -PathType Container } { $dir = (Resolve-Path $_).ProviderPath; break }
            # Is a file, add the parent folder
            { test-path $_ -PathType leaf }      { $dir = (Resolve-Path (Split-Path $_ -Parent)).ProviderPath; break }
            #Isn't valid - don't process...
            default                              { Write-Host "Path `"$dir`" is not a valid directory"; $DoIt = $false; break}
        }

        if ($DoIt) {
            write-verbose "Starting Explorer in path `"$dir`""
            if ($RunAs) {
                #Note: /separate might be needed, or might not work
                #(seems dead maybe around vista)
                #BUT, try "/separate","/root,$dir" as the ArgumentList if necessary
                start-process explorer.exe -ArgumentList $dir -verb runasuser
            }
            elseif ($AsAdmin) {
                start-process explorer.exe -ArgumentList $dir -Verb runas
            }
            else {
                start-process explorer.exe -ArgumentList $dir
            }
        }
    }
}

END { }

