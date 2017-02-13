<#
.SYNOPSIS
    Installs a default set of IIS Components

.DESCRIPTION
    Runs through the Add-WindowsFeature cmdlet to install the expected IIS features (skipping any it finds already installed).

.PARAMETER AllowRestart
    Allows the script to reboot the machine if necessary (it isn't always necessary)

.EXAMPLE
     Install-IIS.ps1

.EXAMPLE
     Install-IIS.ps1 -Verbose -AllowRestart
#>


[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [Alias('AllowReboot', 'Restart', 'Reboot')]
    [switch] $AllowRestart = $false
)

# Define the Paths.
# IIS files should be on I:
# But if there isn't an I: or if it's a network location, it should be C:
"Starting IIS Installation script $(get-date)"

Import-Module ServerManager

"Testing if any required features are already installed"
Function TestInstallStatus {
	param([string[]] $ToTestFor)
	return (Get-WindowsFeature $ToTestFor)
}

# Installing IIS
[string[]] $RequiredFeatures = @()
$RequiredFeatures += 'Web-WebServer'
$RequiredFeatures += 'Web-Common-Http'
$RequiredFeatures += 'Web-Static-Content'
$RequiredFeatures += 'Web-Default-Doc'
$RequiredFeatures += 'Web-Http-Errors'
$RequiredFeatures += 'Web-Http-Redirect'

$RequiredFeatures += 'Web-App-Dev'
$RequiredFeatures += 'Web-Asp-Net'
$RequiredFeatures += 'Web-Net-Ext'
$RequiredFeatures += 'Web-ASP'
$RequiredFeatures += 'Web-CGI'
$RequiredFeatures += 'Web-ISAPI-Ext'
$RequiredFeatures += 'Web-ISAPI-Filter'

$RequiredFeatures += 'Web-Health'
$RequiredFeatures += 'Web-Http-Logging'
$RequiredFeatures += 'Web-Http-Tracing'

$RequiredFeatures += 'Web-Security'
$RequiredFeatures += 'Web-Basic-Auth'
$RequiredFeatures += 'Web-Filtering'

$RequiredFeatures += 'Web-Performance'
$RequiredFeatures += 'Web-Stat-Compression'
$RequiredFeatures += 'Web-Dyn-Compression'

$RequiredFeatures += 'Web-Mgmt-Console'
$RequiredFeatures += 'Web-Scripting-Tools'

$RequiredFeatures += 'NET-WCF-HTTP-Activation45'

$RequiredFeatures += 'WAS-Process-Model'
$RequiredFeatures += 'WAS-NET-Environment'
$RequiredFeatures += 'WAS-Config-APIs'

[string[]] $InstallTheseFeatures = @()
TestInstallStatus $RequiredFeatures | ForEach-Object {
	if (!($_.Installed)) { $InstallTheseFeatures += $_.Name }
}

"Starting installation..."
Try {
	$b = Add-WindowsFeature -Name $InstallTheseFeatures -ErrorAction Stop
	"Installation Results:"
	$b.FeatureResult | ForEach-Object { $_ } | Format-Table DisplayName, RestartNeeded, Success, SkipReason -AutoSize
	if ($b.RestartNeeded) {
		if ($AllowRestart) { Restart-Computer -Force } else { exit 3010 }
	}
	else {
		exit 0
	}
}
Catch {
	"Install failed"
	$_.Exception.Message
	exit
}
