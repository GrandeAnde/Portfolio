# What Is This Script?
This PowerShell script is intended to run nightly. It enumerates all domains in the Active Directory forest, then sets the Global Address List (GAL) and CustomAttribute1 properties for every user and distribution group mailbox in each domain.
Additionally, it performs connectivity checks per domain and logs all major actions and errors via both `start-transcript` and `out-file` logging.

## Why It's Made:
Our organization experienced an issue where an unreachable domain caused this script to misapply GAL policies. We suspect that the `$Domain` variable was `$null`, but the script continued executing and used cached or previous data, leading to incorrect `Set-*` operations.

# The Technical Details & Improvements 
The core logic of the script is retained, but additional actions were added:
* `Test-NetConnection` checks for domain reachability before proceeding.
* Logging of every domain's reachability status.
* Explicit try/catch blocks around all `Set-Mailbox` and `Set-DistributionGroup` calls.
* Use of `-ErrorAction Stop` parameter to convert non-terminating errors into terminating ones.
* Transcript logging for full PowerShell output (diagnostics, warnings, etc.).
* Plans for `-WhatIf` testing before production rollout.

#### Future Improvements
* Improved capturing of PowerShell stream to more dynamically collect warnings.
* Summary report that confirms total number of domains affected and total number of mailboxes that had the policy set (or not set).
* Proactive checking of existing GAL policy so as to minimize unnecessary work (only change what needs to be changed).
* Paramterization to make the script more customizable.
* Change the domain check from checking the output of test-netconnection to testing the `set-*` command output for `$NULL`.
* Consider exporting logs to CSV/JSON for easier parsing and alerting.

## Lessons Learned & Final Verdict 
This is the first time I have seen this error occur.  It made me step back and think abuut PowerShell streams and its pipeline works and ultimately left me with two big conclusions:
* **Prevent errors before they happen** Error catching at critical checks allows the script to pause and make ntelligent and controlled decision about what to do next.  Luckily, reverting the incorrect GAL policies were relatively easy, but it may not be so easy in the next script. 
* **Log what you need where it matters** Logging helps with getting explicit, concise, and relevant data at specific logical choke points.  This makes troubleshooting much easier and enables enhanced scalability. 

##### Further Reading
This was perhaps the most helpful blog post I read:
https://ramiyer.io/understanding-streams-in-powershell/

This excerpt helped give me working examples for future use cases:
https://powershellcookbook.com/recipe/ZPiz/handle-warnings-errors-and-terminating-errors

A concise summary of the 6 streams
https://petri.com/understanding-how-streams-work-in-powershell-7/
