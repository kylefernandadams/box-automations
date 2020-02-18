# Service Account variables
$ServiceAccountUserId = $null

# Maximum direct descendants allowed in a parent personal folder. Default = 15k to adhere to Items per folder scale boundary
$MaxDirectDescendants = 15000
$ItemTotal = 0

# App User variables
$AppUserPrefix = "PersonalFolderAppUser"
$AppUserCount = 0
$AppUserId = $null

# Folder variables
$ParentFolderNamePrefix = "PersonalFolders"
$ParentFolderCount = 0
$ParentFolderId = $null

# Item Details Metadata variables
# Note: You must create an Item Details metadata template with Item Total attribute
$ItemDetailsMDTemplateKey = "itemDetails"
$ItemTotalAttributeKey = "itemTotal"

# Employee MD Variables
# Note: You must create an Employee Profile metadata template. Modify these to match your own employee metadata templates
$EmployeeProfileMDTemplateKey = "employeeProfile"
$FirstNameAttributeKey = "firstName"
$LastNameAttributeKey = "lastName"
$EmailAttributeKey = "email"
$EmployeeIdAttributeKey = "employeeId"

# Stopwatch variable
$Stopwatch = $null

# Main function
Function Start-Script {
    Write-Output "Starting powershell script..."
    $script:StopWatch = [system.diagnostics.stopwatch]::StartNew()

    # Get the parent folder before create personal employee subfolders
    Get-Parent-Personal-Folder

    # Create a single personal folder
    # Add-Personal-Folder `
    #     -FirstName "Richard" `
    #     -LastName "Hendricks" `
    #     -Email "richard@piedpiper.com" `
    #     -EmployeeId "987654321"

    Add-Folders-From-Mock-Employee-Data

    $Stopwatch.Stop()
    Write-Output $Stopwatch
}

# Used to create test folders with mock data stored in employees_*.json files
Function Add-Folders-From-Mock-Employee-Data {
    Try {
        # Get employees json file and convert from JSON to an array of objects
        $Employees = Get-Content -Raw -Path ./employees_10.json | ConvertFrom-Json
        ForEach($Employee in $Employees) {
            Write-Output "Creating employee folder with first name: $($Employee.firstName), last name: $($Employee.lastName), email: $($Employee.email), and $($Employee.employeeNumber)"

            # Check parent folder item count
            Check-Item-Count

            # Add personal folder from mock data
            Add-Personal-Folder `
                -FirstName $Employee.firstName `
                -LastName $Employee.lastName `
                -Email $Employee.email `
                -EmployeeId $Employee.employeeNumber
        }
    }
    Catch {
        Write-Error "Failed to load mock employee data"
        break
    }
}

# Add a personal folder given the parameters passed into the method
Function Add-Personal-Folder {
    Param(
        [string] $FirstName,
        [string] $LastName,
        [string] $Email,
        [string] $EmployeeId
    )
    If($ParentFolderId -ne $null) {
        # Create a new parent folder under the root folder of the App User
        $PersonalFolderId =  box folders:create $ParentFolderId "$($EmployeeId) - $($LastName), $($FirstName) - Personal Files" --as-user=$AppUserId --id-only
        Write-Output "Created new personal folder with id: $($PersonalFolderId)"

        # Set the Item Details metadata on the parent folder
        box folders:metadata:set $PersonalFolderId `
            --template-key=$EmployeeProfileMDTemplateKey `
            --data="$($FirstNameAttributeKey)=$($FirstName)" `
            --data="$($LastNameAttributeKey)=$($LastName)" `
            --data="$($EmailAttributeKey)=$($Email)" `
            --data="$($EmployeeIdAttributeKey)=$($EmployeeId)" `
            --as-user=$AppUserId
        Write-Output "Set Item Details metadata on parent folder id: $($ParentFolderId)"

        # Collaborate the employee user into the peronsal folder.
        # Note this is commented out since the emails used are from a mock data source
        #box folders:collaborations:add $PersonalFolderId --role=co-owner --login=$Email --as-user=$AppUserId
        Write-Output "Collaborated employee user to folder"

        # Increment Item Total
        $script:ItemTotal++
        box folders:metadata:set $ParentFolderId --template-key=$ItemDetailsMDTemplateKey --data="$($ItemTotalAttributeKey)=#$($ItemTotal)" --as-user=$AppUserId
        Write-Output "Set Item Details metadata on parent folder id: $($ParentFolderId)"
    }
    Else {
        Write-Error -Message "Failed to create personal folder. Parent folder id is null!" -ErrorAction Stop
    }
}

# Gets the Parent folder to create personal sub-folders for each employee
Function Get-Parent-Personal-Folder {
    Try {
        # Get the service account user id
        $ServiceAccountUser = box users:get --fields="id,name,login" | ConvertFrom-Json
        $script:ServiceAccountUserId = $ServiceAccountUser.id
        Write-Output "Found service account user id: $($ServiceAccountUserId)"

        # Get the personal folder AppUser which owns the parent folder and child personal folders
        Get-Personal-Folder-AppUser
        Write-Output "AppUser Count: $($AppUserCount)"
        Write-Output "Found personal folder app user id: $($AppUserId)"

        # Get child items of a parent folder including the item details metadata
        $ChildItems = box folders:items 0 --fields="id,name,type,metadata.enterprise.$($ItemDetailsMDTemplateKey)" --as-user=$AppUserId | ConvertFrom-Json
        Write-Output "Found child item count: $($ChildItems.Length)"

        # If there are no child items, then we need to create the parent folder
        If($ChildItems.Length -eq 0) {
            Write-Output "No folders found. Creating new parent folder..."
            Add-Parent-Folder
        }
        Else {
            # There should only be one parent folder per AppUser in the default logic, therefore get element 0
            $FolderItem = $ChildItems[0]

            # Get the Item Total attribute value
            $script:ItemTotal = $FolderItem.metadata.enterprise.itemDetails.itemTotal
            Write-Output "Found child item with id: $($FolderItem.id), name: $($FolderItem.name), type: $($FolderItem.type), and item total: $($ItemTotal)"

            # Set the parent folder id
            $script:ParentFolderId = $FolderItem.id

            # Check parent folder item count
            Check-Item-Count
        }
    }
    Catch {
        Write-Error "Failed to get parent personal folder"
        break
    }
}

Function Check-Item-Count() {
    # If the Item total is greater than or equal to the maximum direct descendants allowed, then Add a new app user and parent folder
    If($ItemTotal -ge $MaxDirectDescendants) {
        Write-Output "Max limit of $($MaxDirectDescendants) has been reached. Creating a new folder..."
        $script:ItemTotal = 0
        $script:ParentFolderCount++
        Add-App-User
        Add-Parent-Folder
    }
}

# Add a new parent folder under the associated App User so that we distribute the total direct descendants across multiple folders
Function Add-Parent-Folder {
    Try {
        # Create a new parent folder under the root folder of the App User
        $script:ParentFolderId =  box folders:create 0 "$($ParentFolderNamePrefix)$($ParentFolderCount + 1)" --as-user=$AppUserId --id-only
        Write-Output "Created new parent folder with id: $($ParentFolderId)"

        # Set the Item Details metadata on the parent folder
        box folders:metadata:set $ParentFolderId --template-key=$ItemDetailsMDTemplateKey --data="$($ItemTotalAttributeKey)=#0" --as-user=$AppUserId
        Write-Output "Set Item Details metadata on parent folder id: $($ParentFolderId)"

        # Collaborate the service account into the parent folder. This will help with a consolidated view of the personal sub-folders
        box folders:collaborations:add $ParentFolderId --role=editor --user-id=$ServiceAccountUserId --as-user=$AppUserId
        Write-Output "Collaborated service account user to folder"
    }
    Catch {
        Write-Error "Failed to create parent folder"
        break
    }
}

# Add an App User to own the Personal parent folders so that we can distribute Items per Owner
Function Add-App-User {
    Try {
        $script:AppUserId = box users:create "PersonalFolderAppUser$($AppUserCount + 1)" --app-user --id-only
        $script:AppUserCount++
        Write-Output "Created app user with id: $($AppUserId)"
    }
    Catch {
        Write-Error "Failed to create app user"
        break
    }
}

# Get the personal folder App User
Function Get-Personal-Folder-AppUser {
    Try {
        # Search for all users with the App User prefix and convert to an array of objects
        $AppUsers = box users:search $AppUserPrefix --fields="id,name,login" | ConvertFrom-Json

        # Set the App User count which will be used for the App User naming convention
        $script:AppUserCount = $AppUsers.Length

        # If the App User search returns 0 results, we need to create a new App User
        If($AppUsers.Length -eq 0) {
            Write-Output "No app users found. Creating new app user..."
            Add-App-User
        }
        Else {
            # Loop through App User results and find the App User with the highest count
            $AppUserName = $AppUserPrefix + $AppUserCount
            Write-Output "Searching for App User with name: $($AppUserName)"
            ForEach($AppUser in $AppUsers) {
                If($AppUserName -eq $AppUser.name) {
                    Write-Output "Found App User with name: $($AppUser.name), id: $($AppUser.id), and login: $($AppUser.login)"
                    $script:AppUserId = $AppUser.id
                }
            }
        }
    }
    Catch {
        Write-Error "Failed to get parent personal folder"
        break
    }
}

Start-Script
