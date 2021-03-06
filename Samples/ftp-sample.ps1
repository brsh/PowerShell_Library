function Ech {
	<#

.SYNOPSIS

Outputs text to the screen with date/time stamp and coloring

.DESCRIPTION

The Ech function is designed to simplify Write-Host commands. It will output
the specified text next to a date/time with color-coding depending on the
type of message it is (standard [white], error [red], and important [yellow].
	
.PARAMETER outtext

The text to output. The parameter name does not need to be specified, and leaving
this parameter off will output a blank line.

.PARAMETER -IsError

Changes the output color to red. Can be abbreviated as -E

.PARAMETER -IsImportant

Changes the output color to yellow. Can be abbreviated as -I

.EXAMPLE

Ech "Hi" -I

Writes Date-Time: Hi to the screen in yellow

.EXAMPLE

Ech

Writes a blank line to the screen

.INPUTS
None. You cannot pipe objects to Set-GHIADInfo.

.OUTPUTS
System.String. Outputs text information to the screen.

.NOTES

Basic output function

#>
	Param (
	[Parameter(mandatory=$false, Position=0 )]
	[String] [AllowNull()] $OutText,
	[Parameter(mandatory=$false)]
	[alias("E", "Err", "Error")]
	[Switch] $IsError,
	[Parameter(mandatory=$false)]
	[alias("I", "Imp", "Bold", "B", "Important")]
	[Switch] $IsImportant,
	[Parameter(mandatory=$false)]
	[alias("D", "Different", "Dif")]
	[Switch] $IsDifferent,
	[Parameter(mandatory=$false)]
	[Switch] $OutToFile
	)
	$Color = "White"
	if ($IsError) { $Color = "Red" }
	if ($IsImportant) { $Color = "Cyan" }
	if ($IsDifferent) { $Color = "Green" }
	If ($OutToFile) {
		$Output = $((Get-Date).ToShortDateString()) + "_" + $(Get-Date -Format "HH:mm:ss") + " $OutText"
		Out-File -InputObject $Output -Append -NoClobber -Encoding Default -FilePath e:\tem-pes\ftp.log
	}
	If ($OutText -eq "") { Write-Host "" }
	else { 
		Write-Host $((Get-Date).ToShortDateString()) $(Get-Date -Format "HH:mm:ss") -ForegroundColor "Gray" -NoNewline
		Write-Host " $OutText" -ForegroundColor $Color }
	}


Ech 
Ech "Starting Script " -IsImportant -OutToFile

$File = "c:\path\file.ext"
$ftp = "ftp://user:password@ftp-site.url.com/file.ext"

Ech "ftp url: $ftp"

$webclient = New-Object System.Net.WebClient
$uri = New-Object System.Uri($ftp)

Ech "Uploading $File..." -OutToFile

Try {
$webclient.UploadFile($uri, $File)
}
Catch #[system.exception]
 {
  Ech $_.Exception.Message -IsError -OutToFile
  Ech "Script Complete with Errors." -IsImportant -OutToFile
  exit 1
 }

Ech "Script Complete." -IsImportant -OutToFile
Exit 0
