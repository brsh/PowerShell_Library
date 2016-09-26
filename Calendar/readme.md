Get-ThisDayInHistory

This script mimics the unix/linux/mac Calendar utility. It checks the data subdirectory for files named 'calendar.*'. It can then display items from Today in history, including up to 10 days before and/or after. 

``` 
.PARAMETER  FormatIt
    Switch sorting and word-wrap on

.PARAMETER  Today
    Specify what day you'd like listed - can be in any valid datetime format (like 09/23 or "March 23")

.PARAMETER  Before
    An integer from 0 to 10 specifying how many days before Today to list

.PARAMETER  After
    An integer from 0 to 10 specifying how many days after Today to list

.PARAMETER  Year
    4-digit number specifying a different year

.EXAMPLE 
    PS C:\> .\Get-ThisDayinHistory.ps1
     
.EXAMPLE 
    PS C:\> .\Get-ThisDayinHistory.ps1 -formatit
 
.EXAMPLE 
    PS C:\> .\Get-ThisDayinHistory.ps1 -today "April 5" -Year 2015 -Before 2 -After 1

.EXAMPLE 
    PS C:\> .\Get-ThisDayinHistory.ps1 -today 04/05 -Year 2015 -Before 2 -After 1
```

### The Calendar Files

The files are straight-up copies of the bsd text files. I've modified these slightly so they 1) are all on one line and 2) are slightly less redundant. I might also have added stuff. 

Format of the files is date tab event text. 

Dates can be 2-digit month slash 2-digit day or 3 character abbreviation for day + First, Second, Third, Fourth, Fifth, or Last (to denote that specific occurence of a day).

Examples:

09/23	Published the calendar script
09/MonFirst	This is the first monday in September

