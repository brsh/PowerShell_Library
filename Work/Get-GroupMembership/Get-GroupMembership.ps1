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


.PARAMETER  Computer
    The computer(s) to query. If left blank, it will discover the local Domain and use that

.PARAMETER  Group
    The group to query

.PARAMETER  Depth
    How deep to recurse (Default is 5 levels)

.PARAMETER  Picture
    Save the group to current directory with filename [Computer]-[Group]-[Timestamp].png

.PARAMETER  Raw
    Don't use the nice tree layout

.PARAMETER  LevelIndicator
    Use this char as the tree depth indicator (Default is hyphen)

.EXAMPLE 
    PS C:\> .\Get-GroupMembership.ps1 -Computer ThatMachine -Group Administrators | ft -autosize

.EXAMPLE 
    PS C:\> get-content computers.txt | .\Get-GroupMembership.ps1 -Group Administrators | ft -autosize

#> 


[CmdletBinding(SupportsShouldProcess=$true)]
param ( 
    [parameter(ValueFromPipeline=$True)]
    [Alias('CN','__Server','ComputerName','IPAddress','Name')]
    [string[]]$Computer,
    [parameter(Mandatory=$true)]
    [string] $group,
    [parameter(Mandatory=$false)]
    [Alias('Limit')]
    [int16] $depth = 5,
    [parameter(Mandatory=$false)]
    [Alias('Save', 'Image', 'Jpg')]
    [switch] $Picture = $false,
    [parameter(Mandatory=$false)]
    [Alias('NoFormat')]
    [switch] $raw = $false,
    [parameter(Mandatory=$false)]
    [Alias('Indent')]
    [char] $LevelIndicator = "-"
)

Begin {
        [int]$script:ItemCount = -1
        [int]$Script:TotalAllUsers = 0

    function Get-DomainGroupMembers {
        param (
            [String]$group,
            [String]$parent,
            [Int]$level = 0
        )
    
        $theGroup = Get-ADGroup -Identity $group
        $theGroupsDomain = (Get-ADDomain (($theGroup.DistinguishedName.Split(",") | ForEach-Object { if ($_ -like "DC=*") { $_ } }) -join ",")).NetBiosName

        $results = Get-ADGroupMember -Identity $group | Sort-Object SamAccountName
        $TotalMembers = $results.count
        
        TheObject -sSam $theGroup.SamAccountName -sName $theGroup.Name -sScope $theGroupsDomain -level $level -sUserOrGroup "Group" -sEnabled "N/A" -sParent $parent -iTotal $TotalMembers

        "Found: {0}" -f $TotalMembers | Write-Verbose
        $counter = 0

        if ($level -lt $Depth) {
            $results | ForEach-Object {
                $counter ++
                $WhatIsTheDomain = (Get-ADDomain (($_.DistinguishedName.Split(",") | ForEach-Object { if ($_ -like "DC=*") { $_ } }) -join ",")).NetBiosName
                $Activity = "Getting members of {0} on {1}" -f $group, $WhatIsTheDomain
                Write-Progress -Id ($level + 1) -Activity $Activity -PercentComplete (($counter / $TotalMembers ) * 100) -Status ("Found {0}" -f $_.SamAccountName)
    
                
                if ($_.ObjectClass -eq "Group" ) { 
                        DomainGroupMembers -Group $_.SamAccountName -parent $theGroup.Name -Level ($level + 1)
                }
                else {
                    $UserIsEnabled = (get-aduser -Identity $_.SamAccountName).Enabled
                    TheObject -sSam $_.SamAccountName -sName $_.Name -sScope $WhatIsTheDomain -level ($level + 1) -sUserOrGroup "User" -sEnabled $UserIsEnabled -sParent $group -sDN $_.DistinguishedName
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
            [String] $Parent
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
        TheObject -sSam $group -level 0 -sName $group -sScope $computername -sUserOrGroup "Group" -sEnabled "N/A" -sParent $Parent -iTotal $TotalMembers
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
                       Get-LocalGroupMembers $Name $level
                    } else {
                       # Enumerate members of domain group.
                       Get-DomainGroupMembers -group $Name -level $level -parent $ADSIGroup.Name
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
                    TheObject -sSam $Name -sName $FullName -sScope $path[-2] -level $level -sUserOrGroup "User" -sEnabled $enabled -sParent $group -sDN $tempDN
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

    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
    $groupname = $groupname -replace $re
    $groupname = $groupname.Replace(" ", "")

    #generate a unique file name (with path included)
    if ($PSCommandPath) {
        $folder = Split-Path -Parent $PSCommandPath
        $folder += '\'
    }
    else {
        $folder = '.\'
    }
    $x = get-date
    $TempFile=[string]::format("{0}_{1}{2:d2}{3:d2}-{4:d2}{5:d2}{6:d2}-{7:d4}.{8}",
        $groupname,
        $x.year,$x.month,$x.day,$x.hour,$x.minute,$x.second,$x.millisecond,
        "png")
    $TempFilePath=[string]::format("{0}{1}",$folder,$TempFile)

    return $TempFilePath
}

    Function DrawIt {
        param ([String]$Text = "Hello World")
        Add-Type -AssemblyName System.Drawing

        #"Creating file {0}" -f $script:filename | Write-Verbose
        
        $height = [int]( $($text | Measure-Object -line).Lines * 22 )
        if ($Height -lt 250 ) {$height = 250 }
        
        $longest = 0
        foreach ($line in $Text.Split("`n")) {
            $hold = $line.Tostring().Length
            if ($hold -gt $longest) { $longest = $hold }
        }
        $length = [int]( $longest * 13)
        
        $bmp = new-object System.Drawing.Bitmap $length,$height
        $font = new-object System.Drawing.Font Consolas,14 
        $brushBg = [System.Drawing.Brushes]::White 
        $brushFg = [System.Drawing.Brushes]::Black 
        $graphics = [System.Drawing.Graphics]::FromImage($bmp) 
        $graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height) 
        $graphics.DrawString($Text,$font,$brushFg,10,10) 
        $graphics.Dispose() 
        $bmp.Save($script:filename) 
    }
    
    function FormatIt {
        param (
            $InfoStackObject
        )
        $InfoStackObject | ForEach-Object {
            $AccountName = ($LevelIndicator.ToString() * $_.Depth)
            $AccountName += $_.FullAccountName
    
            $InfoHash = @{
                Class = $_.Class
                AccountName = $AccountName
                FullName = $_.FullName
                Parent = $_.Parent
                Enabled = $_.Enabled
                MemberCount = $_.Count
                ItemNumber = $_.ItemNumber
            }
    
            $InfoStack = New-Object -TypeName PSObject -Property $InfoHash
    
            #Add a (hopefully) unique object type name
            $InfoStack.PSTypeNames.Insert(0,"ADGroup.Information")
    
            #Sets the "default properties" when outputting the variable... but really for setting the order
            $defaultProperties = @('ItemNumber', 'Class', 'AccountName', 'FullName', 'Enabled', "MemberCount")
            $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
            $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
            $InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
            if ($Picture) {
                $Script:AllResults += $InfoStack
            }
            else {
                $InfoStack
            }
        }
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
            [string] $iTotal
        )

        $AccountName += $sScope
        $AccountName += "\"
        $AccountName += $sSam

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
            Count = $iTotal
            ItemNumber = $script:ItemCount
        }
        $InfoStack = New-Object -TypeName PSObject -Property $InfoHash
    
        #Add a (hopefully) unique object type name
        $InfoStack.PSTypeNames.Insert(0,"ADGroup.Information")
    
        #Sets the "default properties" when outputting the variable... but really for setting the order
        $defaultProperties = @('ItemNumber', 'Class', 'AccountName', 'FullName', 'Scope', 'Parent', 'Depth', 'Enabled', 'Count')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        $InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
        if ($raw) {
            $InfoStack
        }
        else {
            FormatIt $InfoStack
        }
    }
}
Process {
    $Script:AllResults = @()
    if ($Computer.Length -gt 0) {
        ForEach ($ComputerName in $Computer) {
            if ($computername -eq ".") { $computername = $env:COMPUTERNAME }
            $Activity = "Getting members of {0} on {1}" -f $group, $ComputerName
            Write-Progress -Id 0 -Activity $Activity -PercentComplete (10) -Status "Starting subprocess..."
            "Requested group members of {0} on computer {1} - {2}" -f $group, $computername, $computer.count | Write-Verbose
            $filename = GenFileName -groupname ("{0}-{1}" -f $computername, $group)
            Try {
                if ([ADSI]::Exists("WinNT://$computerName/$group,group")) {
                    Get-LocalGroupMembers $group $computername -Parent "{self}"
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
        }
    }
    else {
        $temp = get-adgroup -filter { objectClass -eq "Group" -and (SamAccountName -eq $group -or Name -eq $group) }
        "Requested group members of {0} on local domain" -f $group | Write-Verbose
        $Activity = "Getting members of {0} on local domain" -f $group
        Write-Progress -Id 0 -Activity $Activity -PercentComplete (10) -Status "Starting subprocess..."
        try {
            $domain = (get-addomain).NetBiosName
        }
        catch { $domain = "Name not found" }    
        if ($temp) {
            $filename = GenFileName -groupname ("{0}-{1}" -f $domain, $group)
            Get-DomainGroupMembers $temp.SamAccountName -parent "{self}"
        }
        else {
            $host.ui.WriteErrorLine(("Group {0} in Domain {1} not found" -f $group, $domain))
            break
        }
    }

    if (($Picture) -and ($Script:AllResults)) {
        "Writing Image {0} ..." -f $filename | Write-Verbose
        Write-Progress -Id 0 -Activity $Activity -PercentComplete (80) -Status "Saving picture..."
        $picturetext = $AllResults | format-table -AutoSize | out-string
        DrawIt $picturetext
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