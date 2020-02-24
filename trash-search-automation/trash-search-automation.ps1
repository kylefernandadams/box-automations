# Set to a specific Box user id if you would like to search the trash of a specific user instead of the service account
$AsUserId = $null

# File name to filter by
$ItemName = "my_file_name"

# Login email to filter by
$CreatedByLogin = "persom@example.com"

# Option to restore the file to a specific folder
$RestoreFile = $False
$RestoreParentFolderId = "ADD_PARENT_FOLDER_ID"

# CSV Report params
$CsvReportPath = "./reports"

$Limit = "100"
$Offset = 0
$ItemCount = 1

# Main function
Function Start {
    Write-Output "Searching trashed items by name..."
    # Search-Trashed-Items-By-FileName

    $script:Offset = 0
    $script:ItemCount = 1
    Write-Output "Searching trashed items by name and created_by.login..."
    # Search-Trashed-Items-By-FileName-And-CreatedBy
}

Function Search-Trashed-Items-By-FileName {
    Write-Output "Using offset: $($Offset)"

    # Fields to include in the results
    $Fields = "id,name,type"

    # Query String for the search trashed items request. Check if the As-User Id is populated
    $QueryString = "query=$($ItemName)&fields=$($Fields)&trash_content=trashed_only&type=file&offset=$($Offset)&limit=$($Limit)"
    If($AsUser -ne $null) {
        $Response = box request /search `
            --method=GET `
            --query=$QueryString `
                --as-user=$AsUserId | ConvertFrom-Json | % body
    }
    Else {
        $Response = box request /search `
            --method=GET `
            --query=$QueryString | ConvertFrom-Json | % body
    }
    Write-Output "Found response body: $($Response)"

    $TotalCount = $Response.total_count
    Write-Output "Found total count: $($TotalCount)"

    $TrashedItems = $Response.entries
    Write-Output "Found trashed items: $($TrashedItems.Length)"

    $script:Offset += $TrashedItems.Length
    Write-Output "Set new offset: $($script:Offset)"

    # Loop through the trashed items
    ForEach($Item in $TrashedItems) {
        $ItemCreatedBy = $Item.created_by.login
        Write-Output "$($ItemCount) - Found item with name: $($Item.name), id: $($Item.id), and type: $($Item.type)"

        # Check for a partial match the item name in the results
        If($Item.type -eq "file" -AND
            $Item.name -Match $ItemName) {
            Write-Output "$($ItemCount) - Found MATCHING item with name: $($Item.name), id: $($Item.id), and type: $($Item.type)"

            # We found an item, so create an object and append it to a CSV file
            [PSCustomObject]@{
                Name = $Item.name;
                Id = $Item.id;
                Type = $Item.type
            } | Export-Csv -Path $CsvReportPath/trashed_items_name.csv -Append -NoTypeInformation -Force

            # Check if we need to restore the file since we cant download directly from the trash
            If($RestoreFile -eq $True) {
                # Send post request to restore file from trash
                $AccessToken = box tokens:get
                $RestoreResponse = Invoke-WebRequest -Uri "https://api.box.com/2.0/files/$($Item.id)" `
                -Method "POST" `
                -ContentType "application/json" `
                -Headers @{ "Authorization" = "Bearer $($AccessToken)" } | ConvertFrom-Json

                # Move item to another parent folder
                box files:move $Item.id $RestoreParentFolderId
                Write-Output "Restored file with id: $($Item.id) and moved to folder: $($RestoreParentFolderId)"
            }
        }
        $script:ItemCount++
    }

    # Only continue if the Offset is not equal to the total items in the trash
    If($Offset -lt $TotalCount) {
        Search-Trashed-Items-By-FileName
    }
}

Function Search-Trashed-Items-By-FileName-And-CreatedBy {
    Write-Output "Using offset: $($Offset)"

    # Fields to include in the results
    $Fields = "id,name,type,created_by"

    # Query String for the search trashed items request. Check if the As-User Id is populated
    $QueryString = "query=$($ItemName)&fields=$($Fields)&trash_content=trashed_only&type=file&offset=$($Offset)&limit=$($Limit)"
    If($AsUser -ne $null) {
        $Response = box request /search `
            --method=GET `
            --query=$QueryString `
                --as-user=$AsUserId | ConvertFrom-Json | % body
    }
    Else {
        $Response = box request /search `
            --method=GET `
            --query=$QueryString | ConvertFrom-Json | % body
    }
    Write-Output "Found response body: $($Response)"

    $TotalCount = $Response.total_count
    Write-Output "Found total count: $($TotalCount)"

    $TrashedItems = $Response.entries
    Write-Output "Found trashed items: $($TrashedItems.Length)"

    $script:Offset += $TrashedItems.Length
    Write-Output "Set new offset: $($script:Offset)"

    # Loop through the trashed items
    ForEach($Item in $TrashedItems) {
        $ItemCreatedBy = $Item.created_by.login
        Write-Output "$($ItemCount) - Found item with name: $($Item.name), id: $($Item.id), type: $($Item.type), and created_by login: $($ItemCreatedBy)"

        # Check for a PARTIAL match in the item name AND EXACT match in Created By Login in the results
        If($Item.type -eq "file" -AND
            $Item.name -Match $ItemName -AND
            $ItemCreatedBy -eq $CreatedByLogin) {
            Write-Output "$($ItemCount) - Found MATCHING item with name: $($Item.name), id: $($Item.id), type: $($Item.type), and created_by login: $($ItemCreatedBy)"

            # We found an item, so create an object and append it to a CSV file
            [PSCustomObject]@{
                Name = $Item.name;
                Id = $Item.id;
                Type = $Item.type;
                CreatedBy = $Item.created_by.login
            } | Export-Csv -Path $CsvReportPath/trashed_items_createdby.csv -Append -NoTypeInformation -Force

            # Check if we need to restore the file since we cant download directly from the trash
            If($RestoreFile -eq $True) {
                # Send post request to restore file from trash
                $AccessToken = box tokens:get
                $RestoreResponse = Invoke-WebRequest -Uri "https://api.box.com/2.0/files/$($Item.id)" `
                -Method "POST" `
                -ContentType "application/json" `
                -Headers @{ "Authorization" = "Bearer $($AccessToken)" } | ConvertFrom-Json

                # Move item to another parent folder
                box files:move $Item.id $RestoreParentFolderId
                Write-Output "Restored file with id: $($Item.id) and moved to folder: $($RestoreParentFolderId)"
            }
        }
        $script:ItemCount++
    }

    # Only continue if the Offset is not equal to the total items in the trash
    If($Offset -lt $TotalCount) {
        Search-Trashed-Items-By-FileName-And-CreatedBy
    }
}

Start
