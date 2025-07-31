
# What is this script?
This Batch script allows admins to automate the install of DoD certs on many computers in an enterprise.  It uses the Install Root CLI tool so that they can maintain secure communication with the DoD's infrastructure.

## Why It's Made:
DoD uses a tool called InstallRoot.exe to install DoD certs.  This can be run from the CLI or from the UI tool.  Install Root does not offer any native automation capabilities within its tool.  All automation must be configured by the admins. 
In our enviornment, we have had problems running this on a scheduled basis from orchestration/config tools such as SCCM, and it is unreliable to expect end users to run it periodically.

**This script is intended to automate that process.**  


# The Technical Details
#### Why batch and not PowerShell?

The initial goal was to write a PowerShell script that simply ran installroot.exe cli tool, but we could not get it to run reliably from PowerShell and no root cause was found.  So we had to go with a Batch file.

#### What problems did you face?
1. The DoD uses TAMP files to tell Install Root which certificates, CRL details, and policy metadata to install. 
A TAMP message is a digitally signed, binary-encoded .ir4 file, which prevents tampering or unauthorized use of trusted certificates.  These can only be accessed by the Install Root          application. 
2. If we wanted to install certs manually using PowerShell native tools, we'd need to obtain the certs directly from DISA and completely bypass both TAMP and InstallRoot.  While this is achievable, it would would mean skipping the DoD’s official trust model.

Given that InstallRoot performs all of the trust validation and store placement automatically, it made more sense to automate the process using a .bat file, where it ran consistently and reliably

### What's Under the Hood
This originalyl started as a 2-3 line .bat file deployed by SCCM to run on a schedule.  We often found it did not work but had no idea why since the script did not include logging. 

#### It has evolved to include
* logging and log rotation
* file verification logic
* improved deployment through SCCM

#### What we want to include in the future
* LogInsight ingestion and alerting if certs fail to install
* Server whitelisting (so only important servers and infrastructure are externally monitored)
* Alternatively, centralized logging that is then ingested to loginsight.
* Preferably, writing logs to Event Viewer
* CI/CD pipeline integration



## Lessons Learned & Final Verdict 

This was certainly an eye opener in terms of understanding the evolution of scripting automation.  Not all command line tools play well with PowerShell, presumably because of its more object oriented nature.  Furthermore, the chain of trust that is established in iDoD provided ir4 files were difficult to work with at first, and required an understanding of modern chain if trust solutions and encoding.  

While this project may not be flashy, it taught us a lot about how the DoD secures it's infrastrcture, maintains a high level of trust, and prevents unauthorized access in a very real and operational way.  Ideally, this tool would be made in modern Powershell, but for now, a simple bat file provides a very real and reliable solutions. 

![DoD PKI Architecture](/DoD_PKI.jpg)

##### Further Reading
https://militarycac.com/Windows-Scripts/Automation/DOD_CERT_UPDATE/dodcerts.htm

