
# InstallRoot Utility - PowerShell Version

## Project Overview: From Batch to PowerShell

This project is a complete rewrite of a legacy batch script (`.bat`) used to run the `InstallRoot.exe` certificate utility. The original batch file was functional but difficult to read, maintain, and debug.

The primary goal of this rewrite was to modernize the automation by leveraging the structure, readability, and superior error handling capabilities of PowerShell. This folder contains the new PowerShell version, while the original batch file is archived for comparison, showcasing the clear benefits of the modernized approach.

## Key PowerShell Concepts Showcased

This script demonstrates a significant leap in quality and maintainability by leveraging several key PowerShell features that are impossible to replicate in a simple batch file.

#### 1. Executing Legacy Command-Line Tools

A major challenge when moving from batch to PowerShell is learning how to reliably run older, external executables (`.exe`) that have specific requirements. This script successfully solves this with one simple thing:

*   **The Call Operator (`&`):** You cannot just type the name of an executable if its path is stored in a variable or contains spaces. The call operator (`&`) is the PowerShell-native way to say, "Treat the following string as a command and execute it." This is fundamental to running external programs reliably.
*   It's funny how a trivial operator can make or break something....

#### 2. Parameterization using Arrays

To improve readability and logical separation, all parameters for the `InstallRoot.exe` calls are defined as **arrays** at the top of the script.

**Example:**
```powershell
# Defining arguments as a simple array
$arguments_insert_WCF_ir4 = @(
    "--insert",
    "--uri", 
    "\\share\client_depot\InstallRoot\WCF.ir4"
)

# Executing the command with the array of arguments
& $installrootexe @arguments_insert_WCF_ir4
```


## Next Steps: Refactoring to Hashtable Splatting

While the current script is a major improvement, the next evolution for this tool is to refactor the argument arrays into **hashtables** for use with **Splatting** against the `Start-Process` cmdlet. This is the modern, idiomatic way to run external programs in PowerShell and offers several key advantages.

### Why is Hashtable Splatting a Better Approach?

1.  **Enhanced Readability and Maintainability:**
    A hashtable is self-documenting. Instead of just an ordered list of strings, it's a collection of named keys and values. This makes the purpose of each part of the command explicit and easy for other developers to understand at a glance.

2.  **Robust and Controlled Execution:**
    The `Start-Process` cmdlet offers much greater control than the simple call operator (`&`). By using it with splatting, we can easily add critical parameters like `-Wait` (to force the script to pause until the command finishes) and `-NoNewWindow`. This also allows us to programmatically check the `$LASTEXITCODE` after execution to verify if the command succeeded or failed.

3.  **Flexibility:**
    Adding new parameters to the command becomes trivial. Instead of worrying about argument order, you simply add a new key-value pair to the hashtable.

### Future State Example

Here is how one of the commands would be refactored to use this superior pattern.

**Current State (using an Array):**
```powershell
$arguments_insert_WCF_ir4 = @(
    "--insert",
    "--uri", 
    "\\share\client_depot\InstallRoot\WCF.ir4"
)
& $installrootexe @arguments_insert_WCF_ir4

