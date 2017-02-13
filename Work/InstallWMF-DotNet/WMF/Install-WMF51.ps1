<#
.SYNOPSIS
    Installs Windows Management Framework 5.1 on Servers

.DESCRIPTION
    This script will:
        * test for the existence of WMF 5.1
        * test for compatibility with WMF 5.1
        * and install WMF 5.1, if it can.

    Borrowed heavily from Microsoft's script for installing WMF 5.1 on win 7/2k8R2

.PARAMETER AllowRestart
    Set to True to allow setup to restart the system; default is False

.EXAMPLE
     Install-WMF51.ps1 -AllowRestart:$True

#>


[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [Alias('AllowReboot', 'Restart', 'Reboot')]
    [switch] $AllowRestart = $false
)

$ErrorActionPreference = 'Stop'
$InstallName = "Windows Management Framework"
$InstallVersion = "5.1"
$InstallVersionRegEx = '5.[123456789]*'

Write-Host "Installation Script for $InstallName $WMFVersion"

function New-TerminatingErrorRecord {
    param(
        [string] $exception,
        [string] $exceptionMessage,
        [system.management.automation.errorcategory] $errorCategory,
        [string] $targetObject
    )

    $e = New-Object $exception $exceptionMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $e, $errorId, $errorCategory, $targetObject
    return $errorRecord
}

function Test-Compatibility {
    $returnValue = $true

    Write-Verbose "Checking current version of $InstallName."
    if ($PSVersionTable.PSVersion.ToString() -like $InstallVersionRegEx) {
        Write-Warning "$InstallName $InstallVersion or higher is already installed"
        $returnValue = $false
        exit 0
    }
    else {
        Write-Verbose "Current Version is $($PSVersionTable.PSVersion.ToString())"
    }

    $BuildVersion = [System.Environment]::OSVersion.Version
    Write-Verbose "Checking Current OS Build Version"

    if($BuildVersion.Major -ge '10') {
        Write-Warning "$InstallName $InstallVersion is not supported for Windows 10 and above."
        $returnValue = $false
    }
    else {
        Write-Verbose "Found Build Version $BuildVersion"
    }

    ## OS is below Windows Vista
    if($BuildVersion.Major -lt '6') {
        Write-Warning "$InstallName $InstallVersion is not supported on BuildVersion: {0}" -f $BuildVersion.ToString()
        $returnValue = $false
    }

    ## OS is Windows Vista
    if($BuildVersion.Major -eq '6' -and $BuildVersion.Minor -le '0') {
        Write-Warning "$InstallName $InstallVersion is not supported on BuildVersion: {0}" -f $BuildVersion.ToString()
        $returnValue = $false
    }

    Write-Verbose "Checking for WMF 3"
    ## Check if WMF 3 is installed
    $wmf3 = Get-WmiObject -Query "select * from Win32_QuickFixEngineering where HotFixID = 'KB2506143'"

    if($wmf3) {
        Write-Warning "$InstallName $InstallVersion is not supported when WMF 3.0 is installed."
        $returnValue = $false
    }
    else {
        Write-Verbose "WMF 3.0 Not Found."
    }

    # Check if .Net 4.5 or above is installed
    Write-Verbose "Checking for .Net 4.5 or higher"
    $release = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Release -ErrorAction SilentlyContinue -ErrorVariable evRelease).release
    $installed = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Install -ErrorAction SilentlyContinue -ErrorVariable evInstalled).install

    if($evRelease -or $evInstalled) {
        Write-Warning "$InstallName $InstallVersion requires .Net 4.5."
        $returnValue = $false
    }
    elseif (($installed -ne 1) -or ($release -lt 378389)) {
        Write-Warning "$InstallName $InstallVersion requires .Net 4.5."
        $returnValue = $false
    }
    else {
        Write-Verbose ".Net 4.5 or greater is installed."
    }

    return $returnValue
}


$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

#Create the package path based on:
#  where this script is run
#  the version of installation
#  and the right package for the current OS
Write-Verbose "Creating the package path"
$packagePath = ''
$packageName = ''
switch -regex ((Get-WmiObject win32_operatingsystem).Version.ToString().Trim())  {
    '^6.3*'  { $packageName = 'Win8.1AndW2K12R2-KB3191564-x64.msu'; break }; # Win 8.1 or Server 2012 R2
    '^6.2*'  { $packageName = 'W2K12-KB3191565-x64'; break }; # Win 8 or Server 2012
    '^6.1*'  { $packageName = 'Win7AndW2K8R2-KB3191566-x64'; break }; # Win 7 or Server 2008 R2
}

if ($packageName) {
    $packagePath = Join-Path (Join-Path $scriptPath $InstallVersion) $packageName
}

Write-Verbose "Testing compatibility"
if (Test-Compatibility) {
    if ($packagePath -and (Test-Path $packagePath)) {
        Write-Verbose "Package is valid and exists"
        Write-Verbose "Creating the installation command"
        $wusaExe = "$env:windir\system32\wusa.exe"
        if($PSCmdlet.ShouldProcess($packagePath,"Install $InstallName $InstallVersion Package from:")) {
            $wusaParameters = @("`"{0}`"" -f $packagePath)

            if($AllowRestart) {
                $wusaParameters += @("/quiet")
            }
            else {
                $wusaParameters += @("/quiet", "/norestart")
            }

            $wusaParameterString = $wusaParameters -join " "
            Write-Verbose "And running that command"
            #& $wusaExe $wusaParameterString
            $p = Start-Process $wusaExe -ArgumentList $wusaParameters -wait -NoNewWindow -PassThru
            "Script Complete"
        }
    }
    else {
        Write-Verbose "Could not find the installation file"
        $errorParameters = @{
                            exception = 'System.IO.FileNotFoundException';
                            exceptionMessage = "Expected $InstallName $InstallVersion Package: `"$packageName`" was not found.";
                            errorCategory = [System.Management.Automation.ErrorCategory]::ResourceUnavailable;
                            targetObject = $packagePath
                            }

        $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
    }
}
else {
    Write-Verbose "Something amiss here. Check the Warnings for a reason"
    $errorParameters = @{
                            exception = 'System.InvalidOperationException';
                            exceptionMessage = "$InstallName $InstallVersion cannot be installed as pre-requisites are not met. See documentation: https://go.microsoft.com/fwlink/?linkid=839022";
                            errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                            targetObject = $packagePath
                        }

    $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
}







