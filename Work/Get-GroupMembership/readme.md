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

Command Line:
```
Get-GroupMembership.ps1 [[-Computer] <string[]>] [-group] <string> [[-depth] <int16>] [[-LevelIndicator] <char>] [-Picture] [-raw] [-WhatIf] [-Confirm] [<CommonParameters>]
```

Examples:
```
.\Get-GroupMembership.ps1 -Computer . -Group Administrators | ft -autosize

.\Get-GroupMembership.ps1 -Computer . -Group Administrators -Picture | ft -autosize

.\Get-GroupMembership.ps1 -Computer ThatMachine -Group Administrators | ft -autosize

get-content c:\computer.lst | .\Get-GroupMembership.ps1 -Group Administrators | ft -autosize
```