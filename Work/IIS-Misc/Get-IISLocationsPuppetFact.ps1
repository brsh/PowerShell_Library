#!/bin/false

#Is WebService installed?
$WebInstalled = Get-Service -Name 'W3svc' -ErrorAction SilentlyContinue
if ($WebInstalled) {
	"WebServerInstalled=true"
	#Is WebAdministration Module installed
	if ((Get-Module -ListAvailable).Where{ $_.Name -eq 'WebAdministration' }) {
		#Default WebSite Path and Drive
		Try {
			[string] $DefaultWebPath = @(Get-Website)[0].physicalPath.ToString()
			Switch -Regex ($DefaultWebPath) {
				'^%SystemDrive%.*$'	{ $DefaultWebDrive='C'; break }
				Default				{ $DefaultWebDrive = $DefaultWebPath.Substring(0,1); break }
			}
		}
		Catch {
			$DefaultWebDrive = "Error"
		}
		"IISDefaultWebSitePath=$DefaultWebPath"
		"IISDefaultWebSiteDrive=$DefaultWebDrive"

		#Default Log locations
		Try {
			[string] $DefaultLogPath = (Get-WebConfigurationProperty  "/system.applicationHost/sites/siteDefaults" -name logfile.directory).Value
			Switch -Regex ($DefaultLogPath) {
				'^%SystemDrive%.*$'	{ $DefaultLogDrive='C'; break }
				Default				{ $DefaultLogDrive = $DefaultLogPath.Substring(0,1); break }
			}
		}
		Catch {
			$DefaultLogDrive = "Error"
		}
		"IISLogPath=$DefaultLogPath"
		"IISLogDrive=$DefaultLogDrive"

		#Binary Log Location
		Try {
			[string] $DefaultLogBinPath = (Get-WebConfigurationProperty  "/system.applicationHost/log" -name centralBinaryLogFile.directory).Value
			Switch -Regex ($DefaultLogBinPath) {
				'^%SystemDrive%.*$'	{ $DefaultLogBinDrive='C'; break }
				Default				{ $DefaultLogBinDrive = $DefaultLogBinPath.Substring(0,1); break }
			}
		}
		Catch {
			$DefaultLogBinDrive = "Error"
		}
		"IISLogPathBinary=$DefaultLogBinPath"
		"IISLogDriveBinary=$DefaultLogBinDrive"

		#W3C Log Location
		Try {
			[string] $DefaultLogW3CPath = (Get-WebConfigurationProperty  "/system.applicationHost/log" -name centralW3CLogFile.directory).Value
			Switch -Regex ($DefaultLogW3CPath) {
				'^%SystemDrive%.*$'	{ $DefaultLogW3CDrive='C'; break }
				Default				{ $DefaultLogW3CDrive = $DefaultLogW3CPath.Substring(0,1); break }
			}
		}
		Catch {
			$DefaultLogW3CDrive = "Error"
		}
		"IISLogPathW3C=$DefaultLogW3CPath"
		"IISLogDriveW3C=$DefaultLogW3CDrive"
	}
}
else { "WebServerInstalled=false" }

<#
.SYNOPSIS
    Pulls the location of IIS Default First Web Site and All Logging

.DESCRIPTION
    Designed for Puppet, this script pulls the current location for the Default Web Site and all logs (including Binary and W3C).
	The output is in standard Puppet fact format: key=definition

.EXAMPLE
     Get-IISLocationPuppetFacts.ps1

#>