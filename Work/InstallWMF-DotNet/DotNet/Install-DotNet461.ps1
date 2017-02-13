<#
.SYNOPSIS
    Installs .Net Framework 4.6.1 on Servers

.DESCRIPTION
    This script will:
        * test for the existence of .Net 4.6.1
        * test for compatibility with .Net 4.6.1
        * and install .Net 4.6.1, if it can.

    Borrowed heavily from Microsoft's script for installing WMF 5.1 on win 7/2k8R2

.PARAMETER AllowRestart
    Set to True to allow setup to restart the system; default is False

.EXAMPLE
     Install-DotNet461.ps1 -AllowRestart:$True
#>


[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [Alias('AllowReboot', 'Restart', 'Reboot')]
    [switch] $AllowRestart = $false
)

$ErrorActionPreference = 'Stop'
$InstallName = ".Net Framework"
$InstallVersion = "4.6.1"
$InstallVersionRegEx = '4.6.[123456789]*'

Write-Host "Installation Script for $InstallName $InstallVersion"

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

	# Check the currently installed version of .Net Framework
    Write-Verbose "Checking the currently installed version of $InstallName"
	if (test-path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\') {
	    $release = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Release -ErrorAction SilentlyContinue -ErrorVariable evRelease).release
		if ($release -gt 394000) {
        	Write-Warning "$InstallName $InstallVersion or greater is already installed."
        	$returnValue = $false
			exit 0
    	}
    	else {
        	Write-Verbose "$InstallName $InstallVersion is not installed"
    	}
	}
	else {
		write-verbose "$InstallName $InstallVersion is not installed"
	}

    return $returnValue
}


$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

#Create the package path based on:
#  where this script is run
#  the version of the installation
Write-Verbose "Creating the package path"
$packagePath = ''
$packageName = 'NDP461-KB3102436-x86-x64-AllOS-ENU.exe'

$packagePath = Join-Path (Join-Path $scriptPath $InstallVersion) $packageName
Write-Verbose "Testing compatibility"
if (Test-Compatibility) {
    if ($packagePath -and (Test-Path $packagePath)) {
        Write-Verbose "Package is valid and exists"
        Write-Verbose "Creating the installation command"
        $wusaExe = "$env:windir\system32\wusa.exe"
        if($PSCmdlet.ShouldProcess($packagePath,"Install $InstallName $InstallVersion Package from:")) {
            $wusaParameters = @("`"{0}`"" -f $packagePath)

            if($AllowRestart) {
                $wusaParameters += @("/passive")
            }
            else {
                $wusaParameters += @("/passive", "/norestart")
            }

            $wusaParameterString = $wusaParameters -join " "
            Write-Verbose "And running that command"
            $p = Start-Process $packagePath -ArgumentList $wusaParameters -wait -NoNewWindow -PassThru
			$returnCode = $p.ExitCode
			[bool] $success = $true
			switch ($returnCode) {
				'0'			{ $returnText = "Installation successful"; $success = $true; break }
				'1602'		{ $returnText = "User Cancelled"; $success = $false; break }
				'1603'		{ $returnText = "Fatal Error"; $success = $false; break }
				'1641'		{ $returnText = "Restart Required"; $success = $true; break }
				'3010'		{ $returnText = "Restart Required"; $success = $true; break }
				'5100'		{ $returnText = "Requirements not met"; $success = $false; break }
			}
			if (-not ($success)) {
			    Write-Verbose "An Installation error occurred"
				$errorParameters = @{
										exception = 'System.InvalidOperationException';
										exceptionMessage = "$InstallName $InstallVersion was not installed: $returnText.";
										errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
										targetObject = $packagePath
									}
				$PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
			}
            "Script Complete. $returnCode $returnText"
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
                            exceptionMessage = "$InstallName $InstallVersion cannot be installed as pre-requisites are not met.";
                            errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                            targetObject = $packagePath
                        }
    $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
}







