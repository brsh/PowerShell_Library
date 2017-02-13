<#
.SYNOPSIS
    Sets Default IIS File Locations

.DESCRIPTION
    This script sets the standard locations for IIS Websites and Log files. The Standard location is I:; however, it will utilize the C: if I: does not exist.
	You can force a different drive with the -DriveLetter switch.

.PARAMETER DriveLetter
    Set a different Drive Letter for the folders besides I: or C:. It expects a single alphabet character.

.EXAMPLE
     Set-IISStandardLocations -DriveLetter D

.EXAMPLE
     Set-IISStandardLocations -Verbose
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$false)]
    [Alias('Drive', 'Letter', 'Path')]
	[ValidateScript({$_.ToString().ToUpper() -ne 'C'})]
    [char] $DriveLetter="I"
)

[bool] $WebServerInstalled = $false
Try {
	Write-Verbose "Testing whether IIS/WebServer is installed"
	$WebServerInstalled = (Get-WindowsFeature -Verbose:$false -Name Web-WebServer).Installed
}
Catch {
	Write-Verbose "IIS/WebServer NOT Found"
	$WebServerInstalled = $false
}

if ($WebServerInstalled) {
	"Testing for ${DriveLetter}:\"
	[string] $IISDrive = 'C:\'
	[bool] $MoveIISFiles = $false
	if (test-path "${DriveLetter}:\") {
		if ((Get-WmiObject Win32_LogicalDisk -filter "DeviceID = '${DriveLetter}:'").ProviderName -notmatch "^\\\\*") {
			Write-Verbose "${DriveLetter}:\ found and is local"
			$IISDrive = "${DriveLetter}:\"
			$MoveIISFiles = $true
		}
		else {
			Write-Verbose "${DriveLetter}:\ is NOT local. Continuing with defaults (C:\)"
		}
	}
	else {
		Write-Verbose "${DriveLetter}:\ NOT found. Continuing with defaults (C:\)"
	}

	$InetPubRoot = "${IISDrive}Inetpub"
	$InetPubWWWRoot = "${IISDrive}Inetpub\wwwroot"
	$InetPubLog = "${IISDrive}Inetpub\Log\LogFiles"

	Write-Verbose "Main InetPub Location: $InetPubRoot"
	Write-Verbose "Main WebSite Location: $InetPubWWWRoot"
	Write-Verbose "Main InetLog Location: $InetPubLog"

	Write-Verbose "Testing for WebAdministration Module"
	if ((get-module -ListAvailable -Verbose:$false).Where{$_.Name -eq "WebAdministration"} ) {
		Import-Module WebAdministration -Force -Verbose:$false #  4>$null

		if ($MoveIISFiles) {
			if (test-path $InetPubRoot) {
				Write-Warning "${InetPubRoot} already exists. Not creating!"
			}
			else {
				Write-Verbose "Creating new Root IIS root at $InetPubRoot"
				$null = New-Item -Path $InetPubRoot -type directory -Force -ErrorAction SilentlyContinue
			}

			if (test-path $InetPubWWWRoot) {
				Write-Warning "${InetPubWWWRoot} already exists. Not creating!"
			}
			else {
				Write-Verbose "Copying old WWW Root data to $InetPubWWWRoot"
				$null = New-Item -Path $InetPubWWWRoot -type directory -Force -ErrorAction SilentlyContinue
				$InetPubOldLocation = @(get-website)[0].physicalPath.ToString()
				$InetPubOldLocation =  $InetPubOldLocation.Replace("%SystemDrive%",$env:SystemDrive)
				Copy-Item -Path $InetPubOldLocation -Destination $InetPubRoot -Force -Recurse

				Write-Verbose "Changing the Default Website location to $InetPubWWWRoot"
				Set-ItemProperty 'IIS:\Sites\Default Web Site' -name physicalPath -value $InetPubWWWRoot
			}

			if (test-path $InetPubLog) {
				Write-Warning "${InetPubLog} already exists. Not creating!"
			}
			else {
				Write-Verbose "Changing Log Location to $InetPubLog"
				$null = New-Item -Path $InetPubLog -type directory -Force -ErrorAction SilentlyContinue

				Set-WebConfigurationProperty  "/system.applicationHost/sites/siteDefaults" -name logfile.directory -value $InetPubLog -PSPath 'IIS:\'
				Set-WebConfigurationProperty  "/system.applicationHost/log" -name centralBinaryLogFile.directory -value $InetPubLog -PSPath 'IIS:\'
				Set-WebConfigurationProperty  "/system.applicationHost/log" -name centralW3CLogFile.directory -value $InetPubLog -PSPath 'IIS:\'
			}
		}

		If (Test-Path "C:\inetpub\temp\apppools") {
			Write-Verbose "Temp\AppPools path already exists"
		}
		else {
			Write-Verbose "Creating the temp\apppools folder"
			$null = New-Item -Path "C:\inetpub\temp\apppools" -type directory -Force -ErrorAction SilentlyContinue
		}
	}
	else {
		Write-Warning "WebAdministration Module NOT found. Cannot set paths."
	}
}
else {
	Write-Warning "IIS doesn't seem to be installed. Nothing to do...."
}