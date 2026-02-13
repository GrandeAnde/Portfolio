# Exchange Health Monitoring Script

## What is this script?

This script runs a series of automated health checks against our Exchange environment, gathering critical information on Database Availability Group (DAG) status and overall mail flow health.

## Why It Was Made

Our previous monitoring script, while functional, produced a detailed HTML report that often got lost in the noise of daily emails. We realized that while automation is good, there's always a need for a **Human-In-The-Loop** to ensure the script's output is reviewed and acted upon accordingly.

This new script is designed not just to produce data, but to produce *actionable intelligence*.

## The Technical Details

A primary goal of this project was to focus on portability and maintainability. To achieve this, the script was designed to completely segregate **data** from **code**.

This architecture increases portability and allows the core script logic to remain unchanged—it can even be made read-only if needed—without prohibiting administrators from changing environment-specific variables. All variables are stored in a separate `config.json` file and are called at runtime.

### Benefits of Using JSON

> Using JSON strictly separates the script's logic (the PowerShell code) from its data (the environment configuration), which is a cornerstone of building robust and maintainable automation tools.

Here's why this approach was chosen:

*   **Structure and Reliability:** JSON's key-value structure is parsed natively and reliably by PowerShell's `ConvertFrom-Json` cmdlet. This avoids the need to write complex, brittle string-parsing logic and ensures that the configuration is either loaded perfectly or fails with a clear error, preventing bad data from corrupting the script's execution.

*   **Data Integrity:** The strict format of JSON ensures that data types (like numbers for thresholds and arrays for server lists) are preserved, eliminating the need for manual type conversion.

*   **Maintainability:** As a universal standard, JSON is easy for other administrators to read and edit. It is supported by all modern code editors with features like syntax highlighting and validation, which significantly reduces the risk of human error when modifying the configuration.

## What Problems Did You Face?

Frankly, this was a straightforward script to build once I got a hang of using functions and building custom objects. The process became highly repeatable, and the most difficult aspect was simply keeping track of matching brackets `{}`. Using an editor like VS Code makes this extremely easy to manage.

## What's Under the Hood

The script is composed of multiple functions, each performing a specific check against the Exchange environment. Each check creates a standardized `PSCustomObject`. This process, known as **data normalization**, is critical for ensuring the final data is uniform and can be easily presented in a CSV format.

Each function returns its results to a master variable in the main script. This variable is progressively populated by each function until all checks are complete. Finally, the entire collection of objects is converted into a single CSV file, where an administrator can sort, filter, and manipulate the data as needed.

## Lessons Learned & Final Verdict

This project reinforced two very important lessons in automation:

1.  **Keep Data and Code Separate.** It makes it extremely easy to work on the core logic without ever worrying about hardcoded variables or environment-specific details.

2.  **Data Normalization is Key to Reporting.** It is not enough to simply gather data. You must think ahead about how that data will ultimately be presented and manipulated. Creating a standardized format for your results is the most critical step in producing a meaningful and usable report.
