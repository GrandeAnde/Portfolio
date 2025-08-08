# What Is This Script?
This PowerShell script runs every night and manually sets the GAL for every user mailbox and group mailbox in all domains under a forest.  It logs explicit errors about regarding domain reachability and logs a transcript of all actions.

## Why It's Made:
Our 

# The Technical Details
The core logic of the script is retained, but additional logging and error checking was added.  They were added because we experienced an issue in which a domain was not reachable, and this caused the script to incorrectly apply the wrong GAL policy to the wrong mailboxes.  Our suspicion is that the $DOMAIN variable was $NULL but proceeded to carry on with the script with cached data from a previous object in the pipeline, causing bad data to be included in set-* coommands. 
While we had a transcript runn

#### Future Improvements
* Improved capturing of PowerShell stream to more dynamically collect warnings.
* Summary report that confirms total number of domains affected and total number of mailboxes that had the policy set (or not set).
* Proactive checking of existing GAL policy so as to minimize unnecessary work (only change what needs to be changed).
* Paramterization to make the script more customizable.


## Lessons Learned & Final Verdict 
This is the first time I have seen this error occur.  It made me step back and think aobut PowerShell streams and its pipeline works.  Ultimately, I came to the conclusion that we needed to enhance error catching and logging.  
Error catching would solve the problem of stopping the script and making an intelligent and controlled decision about what to do next.
Logging would help with getting explicit, concise, and relevant data at specific logical choke points. 

##### Further Reading
https://militarycac.com/Windows-Scripts/Automation/DOD_CERT_UPDATE/dodcerts.htm

