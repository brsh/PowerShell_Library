We had a need to unzip some files, renaming the extracted files to match the original zip file name + a time/date stamp.

Now, you'd think that would be simple. MS offers APIs in .Net 4.5, there're com objects, heck - they even wrote Expand-Archive cmdlets!

Piece of cake, right?

The .Net 4.5 APIs, for some reason, aren't available in my Win10, .Net 4.6 virtual machine. Can't use them if it won't let me.

The Com Object... well, they have no rename functionality - not even the copyhere methods.

The Expand-Archive - and this is my favorite - remember how MS says Objects Objects Objects! Well, how easy would it be to pipe the objects from Expand-Archive to a Rename-Item cmdlet? So easy! Exepct Expand-Archive doesn't output objects. Nor does it let you specify individual items to expand - all or nothing, baby. 

I went with the com object - utilizing some trickery to rename each item immediately after extraction. 

I still have a few things to do - like checking for file existence before extraction - but I'm not sure any more work is actually necessary for this script for us.

