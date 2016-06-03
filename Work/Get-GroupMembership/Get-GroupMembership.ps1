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
    function Get-DomainGroupMembers {
        param (
            [String]$group,
            [Int]$level = 1
        )
    
        $results = Get-ADGroupMember -Identity $group | Sort-Object SamAccountName
        $TotalMembers = $results.count
        $counter = 0

        $results | ForEach-Object {
            $counter ++
            $WhatIsTheDomain = (Get-ADDomain (($_.DistinguishedName.Split(",") | ForEach-Object { if ($_ -like "DC=*") { $_ } }) -join ",")).NetBiosName
            $Activity = "Getting members of {0} on {1}" -f $group, $WhatIsTheDomain
            Write-Progress -Id ($level + 1) -Activity $Activity -PercentComplete (($counter / $TotalMembers ) * 100) -Status ("Found {0}" -f $_.SamAccountName)

            if ($_.ObjectClass -eq "Group" ) { 
                TheObject -sSam $_.SamAccountName -sName $_.Name -sScope $WhatIsTheDomain -level $level -sUserOrGroup "Group" -sEnabled "N/A" -sParent $group
                if ($level -le $Depth) {
                    DomainGroupMembers -Group $_.SamAccountName -Level ($level + 1)
                }
            }
            else {
                $UserIsEnabled = (get-aduser -Identity $_.SamAccountName).Enabled
                TheObject -sSam $_.SamAccountName -sName $_.Name -sScope $WhatIsTheDomain -level $level -sUserOrGroup "User" -sEnabled $UserIsEnabled -sParent $group -sDN $_.DistinguishedName
            }
        }
        Write-Progress -Id ($level + 1) -Activity $Activity -Completed
    }
    
    function Get-LocalGroupMembers {
        param (
            [string] $group,
            [string] $computername,
            [Int]$level = 1
        )

        try {
            $ADSIGroup = [ADSI]"WinNT://$computername/$group,group"
        }
        catch {
            $host.ui.WriteErrorLine(("Group {0} on Computer {1} not found" -f $group, $computername))
            break
        }
    
        $Members = @($ADSIGroup.psbase.Invoke("Members"))
        #Write-Progress -Id ($level + 1) -Activity ("Getting members of {0} on {1}" -f $group, $computername) -PercentComplete (1) -Status "Enumerating Members..."
        $TotalMembers = $Members.Count
        $Activity = "Getting members of {0} on {1}" -f $group, $computername
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
                    TheObject -sSam $Name -sName $name -sScope $path[-2] -level $level -sUserOrGroup "Group" -sEnabled "N/A" -sParent $group -sDN $tempDN
                    # Check if this group is local or domain.
                    if ($level -lt $Depth) {
                        if ($Type -eq 'Local') {
                            # Enumerate members of local group.
                            Get-LocalGroupMembers $Name ($level + 1)
                         } else {
                            # Enumerate members of domain group.
                            Get-DomainGroupMembers $Name ($level + 1)
                         }
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
        #Write-Progress -Id ($level + 1) -Activity ("Getting members of {0} on {1}" -f $group, $computername) -PercentComplete (100) -Status "Complete."
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
        
        
        #$filename = ".\foo.png" 
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
            }
    
            $InfoStack = New-Object -TypeName PSObject -Property $InfoHash
    
            #Add a (hopefully) unique object type name
            $InfoStack.PSTypeNames.Insert(0,"ADGroup.Information")
    
            #Sets the "default properties" when outputting the variable... but really for setting the order
            $defaultProperties = @('Class', 'AccountName', 'FullName', 'Enabled')
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
            [string] $sEnabled
        )
    
        $AccountName += $sScope
        $AccountName += "\"
        $AccountName += $sSam
    
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
        }
        $InfoStack = New-Object -TypeName PSObject -Property $InfoHash
    
        #Add a (hopefully) unique object type name
        $InfoStack.PSTypeNames.Insert(0,"ADGroup.Information")
    
        #Sets the "default properties" when outputting the variable... but really for setting the order
        $defaultProperties = @('Class', 'AccountName', 'FullName', 'Scope', 'Parent', 'Depth', 'Enabled')
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
                    TheObject -sSam $group -level 0 -sName $group -sScope $computername -sUserOrGroup "Group" -sEnabled "N/A" -sParent "{self}"
                    Get-LocalGroupMembers $group $computername
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
            TheObject -sSam $temp.SamAccountName -level 0 -sName $temp.Name -sScope $domain -sUserOrGroup "Group" -sDN $temp.DistinguishedName -sEnabled "N/A" -sParent "{self}"
            Get-DomainGroupMembers $temp.SamAccountName
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