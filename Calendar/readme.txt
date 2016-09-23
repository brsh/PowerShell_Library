Get-ThisDayInHistory

Script that mimics the unix/linux/mac Calendar utility. It checks the data subdirectory for files named 'calendar.*'. It can then display items from Today in history, including up to 10 days before and/or after. 

The files are straight-up copies of the bsd text files. I've modified these slightly so they 1) are all on one line and 2) are slightly less redundant.

Format of the files is date tab event text. 

Dates can be 2-digit month slash 2-digit day or 3 character abbreviation for day + First, Second, Third, Fourth, Fifth, or Last (to denote that specific occurence of a day).

Examples:

09/23	Published the calendar script
09/MonFirst	This is the first monday in September

