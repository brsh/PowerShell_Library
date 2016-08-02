<# 
.SYNOPSIS 
Recursive Local and AD Group Membership 

.DESCRIPTION 
This script will inventory group memberships - both local system and AD - and do it recusively - both local system and AD.

Features:
    * Recursive!
    * Recursion depth configurable
    * Local and AD
    * Supports Computer by name, by ip, and, if local, by . (that's a dot, by the way)
    * Outputs to png
    * Outputs objects
    * Supports pipeline (computernames in and users out)
    * Cool tree structure
    * Tree depth indicator configurable
    * Or no tree structure - your choice!

The script is for creating a report, so it will default to a formatted, hierarchical test-only list. BUT, with the -raw switch,
you can output numerous fields as a nice, native PowerShell object - for piping or filtering or sorting.

.PARAMETER  Computer
    The computer(s) to query. If left blank, it will discover the local Domain and use that

.PARAMETER  Domain
    The Domain to query - if you want something other than the current domain

.PARAMETER  Group
    The group to query

.PARAMETER  Depth
    How deep to recurse (Default is 7 levels)

.PARAMETER  Picture
    Save the group to current directory with filename [Computer]-[Group]-[Timestamp].png

.PARAMETER  Path
    The folder in which to save the picture(s) (requires -Picture)

.PARAMETER  Raw
    Output a PS object rather than the nice tree layout - thar be more fields here

.PARAMETER  LevelIndicator
    Use this char as the tree depth indicator (Default is hyphen)

.EXAMPLE 
    PS C:\> .\Get-GroupMembership.ps1 -Computer ThatMachine -Group Administrators

    Outputs the group members from ThatMachine

.EXAMPLE 
    PS C:\> get-content computers.txt | .\Get-GroupMembership.ps1 -Group Administrators

    Outputs the group members from all systems listed in the file computers.txt

.EXAMPLE 
    PS C:\> ".", "server1", "server2" | .\Get-GroupMembership.ps1 -Group Administrators

    Outputs the group members from the local system, server1, and server2

.EXAMPLE 
    PS C:\> .\Get-GroupMembership.ps1 -Computer ThatMachine -Group Administrators -raw

    Outputs a PSObject for further modification or piping to additional cmdlets

.EXAMPLE 
    PS C:\> .\Get-GroupMembership.ps1 -Computer ThatMachine -Group Administrators -picture

    Creates a .png of the data, named a la computer_group_date-time

.EXAMPLE 
    PS C:\> .\Get-GroupMembership.ps1 -Group Administrators
    
    Outputs the group members from the current domain

.EXAMPLE 
    PS C:\> .\Get-GroupMembership.ps1 -Domain MyADDomain -Group Administrators

    Outputs the group members from the domain MyADDomain

#> 


[CmdletBinding(SupportsShouldProcess=$false, DefaultParametersetName='PictureComputer')]
param ( 
    [parameter(Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName='PictureComputer')]
    [Parameter(Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'NoFormatComputer')]
    [Alias('CN','__Server','ComputerName','IPAddress','Name','NetBiosName')]
    [string[]]$Computer,
    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'PictureDomain')]
    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'NoFormatDomain')]
    [string] $Domain,
    [Parameter(Mandatory=$true, ParameterSetName = 'PictureComputer')]
    [Parameter(Mandatory=$true, ParameterSetName = 'PictureDomain')]
    [Parameter(Mandatory=$true, ParameterSetName = 'NoFormatComputer')]
    [Parameter(Mandatory=$true, ParameterSetName = 'NoFormatDomain')]
    [string] $group,
    [Parameter(Mandatory=$false, ParameterSetName = 'PictureComputer')]
    [Parameter(Mandatory=$false, ParameterSetName = 'PictureDomain')]
    [Parameter(Mandatory=$false, ParameterSetName = 'NoFormatComputer')]
    [Parameter(Mandatory=$false, ParameterSetName = 'NoFormatDomain')]
    [Alias('Limit')]
    [ValidateScript({If ($_ -gt 0) { $True } Else { Throw "Depth must be greater than 0" }})]
    [int16] $depth = 7,
    [parameter(Mandatory=$false, ParameterSetName = 'PictureComputer')]
    [Parameter(Mandatory=$false, ParameterSetName = 'PictureDomain')]
    [Parameter(Mandatory=$false, ParameterSetName = 'NoFormatComputer')]
    [Parameter(Mandatory=$false, ParameterSetName = 'NoFormatDomain')]
    [Alias('Indent','')]
    [char] $LevelIndicator = "─",
    [Parameter(Mandatory=$false, ParameterSetName = 'NoFormatComputer')]
    [Parameter(Mandatory=$false, ParameterSetName = 'NoFormatDomain')]
    [Alias('NoFormat','AsObject','Object','NotText')]
    [switch] $raw = $false,
    [Parameter(Mandatory=$false, ParameterSetName = 'PictureComputer')]
    [Parameter(Mandatory=$false, ParameterSetName = 'PictureDomain')]
    [Alias('Save', 'Image', 'Jpg')]
    [switch] $Picture = $false,
    [Parameter(Mandatory=$false, ParameterSetName = 'PictureComputer')]
    [Parameter(Mandatory=$false, ParameterSetName = 'PictureDomain')]
    [Alias('Path', 'SaveTo')]
    [ValidateScript({
        If (Test-Path -Path $_.ToString() -PathType Container) {
            $true
        }
        else {
            Throw "$_ is not a valid destination folder. Enter in 'c:\directory' format"
        }
    })]
    [string] $folder = $(if ($PSCommandPath)  { (Split-Path -Parent $PSCommandPath) + '\' } else { '.\' } )
)

Begin {
    ## Declarations and Initializations
    [int]$script:ItemCount = -1
    [int]$Script:TotalAllUsers = 0
    $Group = (Get-Culture).TextInfo.ToTitleCase($group)

    $folder = (resolve-path $folder).ProviderPath
    if (-not $folder.EndsWith("\")) { $folder += "\" }

    if (get-module -ListAvailable ActiveDirectory) {
        "Importing the ActiveDirectory Module" | Write-Verbose
        Import-Module ActiveDirectory -Verbose:$false
    }
    else {
        Write-Host "Fatal Error: ActiveDirectory Module NOT FOUND" -ForegroundColor Red
        exit
    }

    function Get-DomainGroupMembers {
        param (
            [String]$group,
            [String]$parent,
            [Int]$level = 0,
            [String] $System,
            [String] $HomeDomain
        )
    
        $theGroup = Get-ADGroup -Identity $group -Server $HomeDomain

        $results = Get-ADGroupMember -Identity $group -Server $HomeDomain | Sort-Object SamAccountName
        $TotalMembers = $results.count
        
        TheObject -sSam $theGroup.SamAccountName -sName $theGroup.Name -sScope $HomeDomain -level $level -sUserOrGroup "Group" -sEnabled "" -sParent $parent -iTotal $TotalMembers -sSystem $System

        $counter = 0

        if ($level -lt $Depth) {
            $results | ForEach-Object {
                $counter ++
                $WhatIsTheDomain = (Get-ADDomain (($_.DistinguishedName.Split(",") | ForEach-Object { if ($_ -like "DC=*") { $_ } }) -join ",")).NetBiosName
                $Activity = "Getting members of {0} on {1}" -f $group, $WhatIsTheDomain
                Try {
                    Write-Progress -Id ($level + 1) -Activity $Activity -PercentComplete (($counter / $TotalMembers ) * 100) -Status ("Found {0}" -f $_.SamAccountName)
                }
                Catch { 
                    "Non-Fatal Error with ProgressBar. Group/User: {0}" -f $group | Write-Verbose 
                }
                
                if ($_.ObjectClass -eq "Group" ) { 
                        Get-DomainGroupMembers -Group $_.SamAccountName -parent $theGroup.Name -Level ($level + 1) -System $System -HomeDomain $WhatIsTheDomain
                }
                else {
                    $UserIsEnabled = (get-aduser -Identity $_.SamAccountName).Enabled
                    TheObject -sSam $_.SamAccountName -sName $_.Name -sScope $WhatIsTheDomain -level ($level + 1) -sUserOrGroup "User" -sEnabled $UserIsEnabled -sParent $group -sDN $_.DistinguishedName -sSystem $System
                }
            }
        }
        Write-Progress -Id ($level + 1) -Activity $Activity -Completed
    }

    function Get-LocalGroupMembers {
        param (
            [string] $group,
            [string] $computername,
            [Int]$level = 1,
            [String] $Parent,
            [String] $System
        )

        try {
            $ADSIGroup = [ADSI]"WinNT://$computername/$group,group"
        }
        catch {
            $host.ui.WriteErrorLine(("Group {0} on Computer {1} not found" -f $group, $computername))
            break
        }
    
        $Members = @($ADSIGroup.psbase.Invoke("Members"))
        $TotalMembers = $Members.Count
        
        $Activity = "Getting members of {0} on {1}" -f $group, $computername
        TheObject -sSam $group -level 0 -sName $group -sScope $computername -sUserOrGroup "Group" -sEnabled "" -sParent $Parent -iTotal $TotalMembers -sSystem $System
        $counter = 0
    
        $Members | ForEach-Object {
            Try {
                $counter ++
                $tempDN = ""
                $Name = ([ADSI]$_).InvokeGet("Name")
                $AdsPath = (([ADSI]$_).InvokeGet("Adspath"))
                $Path = $AdsPath.Split('/',[StringSplitOptions]::RemoveEmptyEntries)

                Write-Progress -Id ($level + 1) -Activity $Activity -PercentComplete (($counter / $TotalMembers ) * 100) -Status ("Found {0}" -f $Name)

                # Check if this member is a group.
                $isGroup = ([ADSI]$_).InvokeGet("Class")
    
                if (($Path -contains $computername) -or ($path -contains "NT AUTHORITY")) {
                    $Type = 'Local'
                    $tempDN = $AdsPath
                } 
                Else {
                    $Type = 'Domain'
                    try {
                        if ($isGroup -eq "User") {
                            $tempDN = (get-aduser $Name).DistinguishedName
                        }
                        else {
                            $tempDN = (get-adgroup $Name).DistinguishedName
                        }
                    }
                    catch { $tempDN = "Unknown" }
                }
    
                if ($isGroup.Contains("Group")) {
                    # Check if this group is local or domain.
                    if ($Type -eq 'Local') {
                       # Enumerate members of local group.
                       Get-LocalGroupMembers $Name $level -System $System
                    } else {
                       # Enumerate members of domain group.
                        $HomeDomain = (Get-ADDomain (($tempDN.Split(",") | ForEach-Object { if ($_ -like "DC=*") { $_ } }) -join ",")).NetBiosName
                        Get-DomainGroupMembers -group $Name -level $level -parent $ADSIGroup.Name -System $System -HomeDomain $HomeDomain
                    }
                }
                else {
                    try {
                        $UserFlags = ([ADSI]$AdsPath).InvokeGet("UserFlags")
                        $enabled = -not [boolean]($UserFlags -band "0x"+"512".PadLeft($UserFlags.ToString().Length, "0"))
                    }
                    Catch { $enabled = "Unknown" }
                    try {
                        $FullName = ([ADSI]$_).InvokeGet("FullName")
                    }
                    Catch { $FullName = "" }
                    TheObject -sSam $Name -sName $FullName -sScope $path[-2] -level $level -sUserOrGroup "User" -sEnabled $enabled -sParent $group -sDN $tempDN -sSystem $System
                }
            } Catch {
                $host.ui.WriteWarningLine(("GLGM {0}" -f $_.Exception.Message))
            }
        }
        Write-Progress -Id ($level + 1) -Activity $Activity -Completed
    }

function GenFileName {
    param (
        [string] $groupname
    )
    #Let's remove invalid filesystem characters and ones we just don't like in filenames
    $invalidChars = ([IO.Path]::GetInvalidFileNameChars() + "," + ";") -join '' 
    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
    $groupname = $groupname -replace $re
    $groupname = $groupname.Replace(" ", "")

    #generate a unique file name (with path included)
    $x = get-date
    $TempFile=[string]::format("{0}_{1}{2:d2}{3:d2}-{4:d2}{5:d2}{6:d2}-{7:d4}.{8}",
        $groupname,
        $x.year,$x.month,$x.day,$x.hour,$x.minute,$x.second,$x.millisecond,
        "png")
    $TempFilePath=[string]::format("{0}{1}",$folder,$TempFile)
    "Output: {0}" -f $TempFilePath | Write-Verbose
    return $TempFilePath
}

    Function DrawIt {
        param ([String]$Text = "Hello World")
        Add-Type -AssemblyName System.Drawing

        $height = [int]( ($($text | Measure-Object -line).Lines * 22) + 25 )
        if ($Height -lt 350 ) {$height = 350 }
        
        $longest = 0
        foreach ($line in $Text.Split("`n")) {
            $hold = $line.Tostring().Length
            if ($hold -gt $longest) { $longest = $hold }
        }
        $length = [int]( $longest * 12)
        
        $bmp = new-object System.Drawing.Bitmap $length,$height
        $font = new-object System.Drawing.Font Consolas,14 
        $brushBg = [System.Drawing.Brushes]::White 
        $brushFg = [System.Drawing.Brushes]::Black 
        $graphics = [System.Drawing.Graphics]::FromImage($bmp) 
        $graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height) 
        $graphics.DrawString($Text,$font,$brushFg,10,10) 
        $graphics.Dispose() 
        "Writing picture..." | Write-Verbose
        $bmp.Save($script:filename) 
    }
   
    function TheObject {
        param (
            [string] $sSam,
            [string] $sName,
            [string] $sDN,
            [string] $sScope,
            [string] $sParent,
            [string] $level,
            [string] $sUserOrGroup,
            [string] $sEnabled,
            [string] $iTotal,
            [string] $sSystem
        )

        $AccountName += $sScope
        $AccountName += "\"
        $AccountName += $sSam

        $HierarchyName = "├"
        $HierarchyName += ($LevelIndicator.ToString() * $level)
        $HierarchyName += $AccountName

        $script:ItemCount += 1
        $Script:TotalAllUsers += $iTotal
    
        $InfoHash =  @{
            AccountName = $sSam
            FullAccountName = $AccountName
            FullName = $sName
            DistinguishedName = $sDN
            Scope = $sScope
            Parent = $sParent
            Depth = $level
            Class = $sUserorGroup
            Enabled = $sEnabled
            Members = $iTotal
            Item = $script:ItemCount
            System = $sSystem
            Hierarchy = $HierarchyName
        }
        $InfoStack = New-Object -TypeName PSObject -Property $InfoHash
    
        #Add a (hopefully) unique object type name
        $InfoStack.PSTypeNames.Insert(0,"ADGroup.Information")
    
        #Sets the "default properties" when outputting the variable... but really for setting the order
        $defaultProperties = @('FullAccountName', 'FullName', 'Parent', 'Depth')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        $InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
        if ($raw) {
            $InfoStack
        }
        else {
            $Script:AllResults += $InfoStack
        }
    }
    
    function GenFormattedOutput {
        param (
            [string] $header,
            [string] $footer,
            [bool] $picture = $false
        )
        $outtext = $header
        $outtext += ($Script:AllResults | format-table -AutoSize Hierarchy, FullName, Enabled, Class, @{Label="Members"; expression={$_.Members}; align='right'} | out-string).Trim("`n").TrimStart("`n")
        $outtext += $footer
        if ($picture) {
            DrawIt $outtext
        }
        else {
            $outtext
        }
    }

    function GenHeader {
        param (
            [string] $Group,
            [string] $ComputerName
        )
        [string] $head = "Script Name: {0}" -f $PSCommandPath | Out-String
        $head += "Script Date: {0}" -f (get-date (get-item $PSCommandPath).LastWriteTime -UFormat "%a, %b %d, %Y -- %r UTC%Z") | Out-String
        $head += "" | Out-String
        $head += "Start Time : {0}" -f (Get-Date -UFormat "%a, %b %d, %Y -- %r UTC%Z") | Out-String
        $head += "" | Out-String
        $head += "`tMembers of the `"{0}`" group on {1}" -f $group, $ComputerName.ToUpper() | Out-String
        $head
    }

    function GenFooter {
        [string] $foot = "`tMember Count: {0}" -f ($Script:AllResults.Count - 1) | Out-String
        $foot += "" | Out-String
        $foot += "End Time  : {0}" -f (Get-Date -UFormat "%a, %b %d, %Y -- %r UTC%Z") | Out-String
        $foot
    }

}
Process {
    $Script:AllResults = @()
    if ($Computer.Length -gt 0) {
        ForEach ($ComputerName in $Computer) {
            [int]$script:ItemCount = -1
            [int]$Script:TotalAllUsers = 0
            if ($computername -eq ".") { $computername = $env:COMPUTERNAME }
            $ComputerName = $ComputerName.ToUpper()
            $header = GenHeader -Group $group -ComputerName $ComputerName
            $Activity = "Getting members of {0} on {1}" -f $group, $ComputerName
            Write-Progress -Id 0 -Activity $Activity -PercentComplete (10) -Status "Starting Group Enumeration Subprocess..."
            "Requested group members of {0} on computer {1}" -f $group, $computername | Write-Verbose
            if ($Picture) { $filename = GenFileName -groupname ("{0}-{1}" -f $computername, $group) }
            Try {
                if ([ADSI]::Exists("WinNT://$computerName/$group,group")) {
                    Get-LocalGroupMembers $group $computername -Parent "{self}" -System $ComputerName
                }
                else {
                    $host.ui.WriteErrorLine(("Group {0} on Computer {1} not found" -f $group, $computername))
                    Write-Progress -Id 0 -Activity ("Complete: members of {0} on {1}" -f $group, $ComputerName) -PercentComplete (100) -Status "Could not find group."
                }
            }
            catch {
                $host.ui.WriteErrorLine(("Group {0} on Computer {1} not found" -f $group, $computername))
                Write-Progress -Id 0 -Activity ("Complete: members of {0} on {1}" -f $group, $ComputerName) -PercentComplete (100) -Status "Could not find group."
                break
            }

            $footer = GenFooter

            if (-not $raw) {
                GenFormattedOutput -header $header -footer $footer -picture $Picture
            }

            $Script:AllResults = $()
        }
    }
    else {
        try {
            if ($Domain) {
                "Testing if domain {0} exists" -f $domain | Write-Verbose
                $Domain = (get-addomain -Identity $Domain).NetBiosName
            }
            else {
                "Testing for local domain" | Write-Verbose
                $Domain = (get-addomain).NetBiosName
            }
            "Found domain {0}" -f $domain | Write-Verbose
        }
        catch { $Domain = "Name not found" }
        
        $temp = get-adgroup -filter { objectClass -eq "Group" -and (SamAccountName -eq $group -or Name -eq $group) } -server $domain
        "Requesteing group members of {0} on {1} domain" -f $group, $Domain | Write-Verbose
        $Activity = "Getting members of {0} on {1} domain" -f $group, $Domain
        Write-Progress -Id 0 -Activity $Activity -PercentComplete (10) -Status "Starting Group Enumeration Subprocess..."

        if ($temp) {
            $header = GenHeader -Group $group -ComputerName $Domain
            if ($Picture) { $filename = GenFileName -groupname ("{0}-{1}" -f $Domain, $group) }
            Get-DomainGroupMembers $temp.SamAccountName -parent "{self}" -System $Domain -HomeDomain $Domain
        }
        else {
            $host.ui.WriteErrorLine(("Group {0} in Domain {1} not found" -f $group, $Domain))
            break
        }

        $footer = GenFooter

        if (-not $raw) {
            GenFormattedOutput -header $header -footer $footer -picture $Picture
        }

        $Script:AllResults = $()
    }

    Write-Progress -Id 0 -Activity $Activity -Completed


}
END {
    #################################
    ### Clean Up
    #################################
    
    if (get-module ActiveDirectory) {
        Write-Verbose "Removing the ActiveDirectory module from memory"
        Remove-Module ActiveDirectory
    }
}