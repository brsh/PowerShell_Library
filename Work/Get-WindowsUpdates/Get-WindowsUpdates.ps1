<#
.SYNOPSIS
    Apply all pending Windows Updates on the Local Computer

.DESCRIPTION
    A script to install all pending Windows Updates in an unattended fashion. Reboot is optional.

.PARAMETER AllowRestart
    Set to True to allow setup to restart the system; default is False

.EXAMPLE
     Get-WindowsUpdates.ps1 -AllowRestart:$true

#>


[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [Alias('AllowReboot', 'Restart', 'Reboot')]
    [switch] $AllowRestart = $false,
	[Parameter(Mandatory=$false)]
	[int16] $LimitNumberOfUpdatesTo = 0
)

$ErrorActionPreference = 'Stop'
#Requires -Version 2.0

$NeedToReboot = $false

#Checking for available updates
$updateSession = new-object -com "Microsoft.Update.Session"
write-progress -Activity "Updating" -Status "Checking for available updates"
$updates=$updateSession.CreateupdateSearcher().Search($criteria).Updates

if ($Updates.Count -eq 0)  { "There are no applicable updates."}
else {
	$date = get-date
	$Count = 0
	$downloader = $updateSession.CreateUpdateDownloader()
	$UpdatesToInstall = New-object -com "Microsoft.Update.UpdateColl"

	foreach ($Update in $Updates) {
		$Count ++
		if ($LimitNumberOfUpdatesTo -gt 0) {
			if ($Count -gt $LimitNumberOfUpdatesTo) { break }
		}
		write-progress -Activity 'Downloading Updates' -percentComplete (($Count / $Updates.Count)*100) -CurrentOperation "$([System.Math]::Round(($Count / $Updates.Count)*100))% Complete" -Status "Downloading $($Updates.Count) updates; started at $date"
		$UpdateToDownload = New-object -com "Microsoft.Update.UpdateColl"
		$UpdateToDownload.Add($Update) | Out-Null
		$downloader.Updates = $UpdateToDownload
		$Result = $downloader.Download()
		if (($Result.Hresult -eq 0) -and (($result.resultCode -eq 2) -or ($result.resultCode -eq 3)) ) {
			$updatesToInstall.Add($Update) | Out-Null
		} Else {
			Write-Warning "$($Update.Title) Failed to download!"
		}
		[System.Runtime.Interopservices.Marshal]::ReleaseComObject($UpdateToDownload) | Out-Null

	}

	$date = get-date
	$Count = 0
	$installer = $UpdateSession.CreateUpdateInstaller()
	foreach ($Update in $UpdatesToInstall) {
		$Count ++
		if ($LimitNumberOfUpdatesTo -gt 0) {
			if ($Count -gt $LimitNumberOfUpdatesTo) { break }
		}
		write-progress -Activity 'Installing Updates' -percentComplete (($Count / $UpdatesToInstall.Count)*100) -CurrentOperation "$([System.Math]::Round(($Count / $UpdatesToInstall.Count)*100))% Complete" -Status "Installing $($UpdatesToInstall.Count) updates started at $date"
		$UpdateToInstall = New-object -com "Microsoft.Update.UpdateColl"
		$UpdateToInstall.Add($Update) | Out-Null
		$installer.Updates = $UpdateToInstall
		$installationResult = $installer.Install()
		# A holder for the current rebootRequired result
		if ($installationResult.rebootRequired -and (!($NeedToReboot))) { $NeedToReboot = $true }
		[System.Runtime.Interopservices.Marshal]::ReleaseComObject($UpdateToInstall) | Out-Null
	}
}

Write-Progress -Activity 'Completed' -Completed
#Reboot if autorestart is enabled and one or more updates are requiring a reboot
if ($AllowRestart -and $NeedToReboot) {
	"Reboot requested; rebooting..."
	Restart-Computer -Force
}
elseif ((!$AllowRestart) -and $NeedToReboot) {
	"Restart requested but not performed."
}
"Script Complete."
