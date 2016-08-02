We had a need (as so many of us do) to inventory/audit specific groups on specific servers (and domains) for membership. In general, we needed to list all the members of, say, the local administrators group on several servers. Well, we've been doing that manually, connecting to each system and taking screenshots of the groups... then starting ADUC and taking screenshots of the member groups... then taking screenshots of those member groups... etc. ad infiniti. Painful.

I had an old vbscript that did this, but we weren't using it. And it was old. And it was vbscript.

Now, how hard could it be to re-write that simple vbscript into Powershell? There already were functions that did kinda what I wanted (get-adgroupmember, for example). 

BUT nothing did quite what I wanted. And then I wanted to make pictures of the info??!!! That's just crazy talk.

So, long story short: this script will inventory group memberships - both local system and AD - and do it recusively - both local system and AD. 

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
* Line Item and Group Member counts

The Default output is remote style as string/text. Use the -raw switch to get PSObjects.

Command Line:
```
C:\Scripts\GetGroupMembers\Get-GroupMembership.ps1 -Computer <String[]> -group <String> [-depth <Int16>] [-LevelIndicator <Char>] [-Picture] [-folder <String>]

C:\Scripts\GetGroupMembers\Get-GroupMembership.ps1 -Computer <String[]> -group <String> [-depth <Int16>] [-LevelIndicator <Char>] [-raw]

C:\Scripts\GetGroupMembers\Get-GroupMembership.ps1 [-Domain <String>] -group <String> [-depth <Int16>] [-LevelIndicator <Char>] [-raw]

C:\Scripts\GetGroupMembers\Get-GroupMembership.ps1 [-Domain <String>] -group <String> [-depth <Int16>] [-LevelIndicator <Char>] [-Picture] [-folder <String>]
```

Examples:
```
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
```