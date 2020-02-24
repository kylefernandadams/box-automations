# Trash Search Automation Script
The Trash Search automation script contains an examples to help search for files within a service account or admin's trash.

## Rationale
When creating a closed folder structure in Box, a service account or admin account will often own an entire departmental or personal folder hierarchy. Since the user owns all of the content any type of administrative activity to find trashed files associated with a specific user becomes laborious manual task.

## Examples
1. [Search Trash and Filter by File Name:](/trash-search-automation/trash-search-automation.ps1#L32) A PowerShell function to search for a specific term in the service account or admin's trash and to find a PARTIAL match on the file name. Then optionally, restore the file and move it to a target parent folder.
2. [Search Trash and Filter by File Name and Created By Login:](/trash-search-automation/trash-search-automation.ps1#L102) A PowerShell function to search for a specific term in the service account or admin's trash and to find a PARTIAL match on the file name AND an EXACT match on the created_by login email address. Then optionally, restore the file and move it to a target parent folder.

## Pre-Requisites
1. Ensure you've completed pre-requisites in the [parent project documentation](../README.md)
2. OPTIONAL: Set the [AsUserId](/trash-search-automation/trash-search-automation.ps1#L2) variable.
3. Set the [ItemName](/trash-search-automation/trash-search-automation.ps1#L5) variable.
4. Set the [CreatedByLogin](/trash-search-automation/trash-search-automation.ps1#L8) variable.
5. Set the [RestoreFile](/trash-search-automation/trash-search-automation.ps1#L11) variable to `$true` or `$false` depending on if you would like to restore the files and move them to a target parent folder.
    * If [RestoreFile](/trash-search-automation/trash-search-automation.ps1#L11) is set to `$true`, manually create a new Folder using the BoxCLI.

```
box folders:create 0 eDiscoFolder-123

```

    * If [RestoreFile](/trash-search-automation/trash-search-automation.ps1#L11) is set to `$true`, set the [RestoreParentFolderId](/trash-search-automation/trash-search-automation.ps1#L12) id to the folder id that was just created.

6. Set the [CsvReportPath](/trash-search-automation/trash-search-automation.ps1#L15) variable to the local directory in which to create the CSV report.
7. Uncomment [Search-Trashed-Items-By-FileName](/trash-search-automation/trash-search-automation.ps1#L24) to enable the search by file name example.
8. Uncomment [Search-Trashed-Items-By-FileName-And-CreatedBy](/trash-search-automation/trash-search-automation.ps1#L29) to enable the search by file name and created by login example.
9. If running on macOS, enable a powershell session by executing the `pwsh` commmand.
10. Run the example...
```
PS box-powershell-automations/trash-search-automation> ./trash-search-automation.ps1                       
Searching trashed items by name and created_by.login...
Using offset: 0
Found response body: @{total_count=996; entries=System.Object[]; limit=100; offset=0}
Found total count: 996
```

## Disclaimer
This project is a collection of open source examples and should not be treated as an officially supported product. Use at your own risk. If you encounter any problems, please log an [issue](https://github.com/kylefernandadams/box-automations/issues).

## License

The MIT License (MIT)

Copyright (c) 2020 Kyle Adams

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
