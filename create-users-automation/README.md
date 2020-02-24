# Create Users Automation
The Create Users Automation contains an example script to help provision users at scale leveraging a service account and app users.

## Scale Boundaries
This script is designed to help Box adhere to the following scale boundaries:
* Items per owner (several million): Distributes ownership across multiple App Users.
* Child items per folder (15k items): Distributes personal folders across a sub-folder owned by App Users.
* Collaborations received by a user (5k collaborations):
  * Leverage a Service Account that is dedicated to user provisioning.
  * Personal folders are not created at the root of the Service Account or App User.

## Pre-Requisites
1. Ensure you've completed pre-requisites in the [parent project documentation](../README.md)
2. Create a Metadata Template in the [Box Admin Console](https://app.box.com/master/metadata/templates) with the name `Item Details` and one text attribute called `Item Total`
3. Create or leverage an existing employee metadata template.
4. Update the [Employee MD Template Key](/create-users-automation.ps1#L21) and corresponding variables.
> Note: You can retrieve the MD template key and attribute keys by using the box metadata-templates BoxCLI command....

```
kadams@mbp Developer % box metadata-templates

{
        "id": "3db66649-1e2b-439b-8873-a93010d06b4e",
        "type": "metadata_template",
        "templateKey": "employeeProfile",
        "scope": "enterprise_EID,
        "displayName": "Employee Profile",
        "hidden": false,
        "copyInstanceOnItemCopy": false,
        "fields": [
            {
                "id": "7e7c974b-9a0e-466a-b204-0049990a62bf",
                "type": "string",
                "key": "employeeId",
                "displayName": "Employee Id",
                "hidden": false
            },
            {
                "id": "ac295665-dac1-4e6e-a2c2-602c389cbb45",
                "type": "string",
                "key": "firstName",
                "displayName": "First Name",
                "hidden": false
            },
            {
                "id": "853214e3-df6e-45ce-88e6-8a8feb2d0b89",
                "type": "string",
                "key": "lastName",
                "displayName": "Last Name",
                "hidden": false
            },
            {
                "id": "6cd21679-7cf4-4d22-b8b3-40502969a12f",
                "type": "string",
                "key": "email",
                "displayName": "Email",
                "hidden": false
            }
        ]
    }
```

5. Update the [Add-Personal-Folder Function](/create-users-automation.ps1#L81) to reflect the metadata template created in the previous step.
6. When using mock data with the [Add-Folders-From-Mock-Employee-Data](/create-users-automation.ps1#L58) function, be sure to comment out the [add collaborator command.](/create-users-automation.ps1#L105) The emails are fake and will not work.
7. When adding real users, uncomment the [add collaborator command.](/create-users-automation.ps1#L105)
8. Create your own implementation to retrieve a list of users to create whether it be from existing users in Box, an LDAP query, or API calls to your IdP.

## Mock Employee Data
* Generate 10 Employees: [employees_10.json](/employees_10.json)
* Generate 100 Employees: [employees_100.json](/employees_100.json)
* Generate 1000 Employees: [employees_1000.json](/employees_1000.json)

## Disclaimer
This project is a collection of open source examples and should not be treated as an officially supported product. Use at your own risk. If you encounter any problems, please log an [issue](https://github.com/kylefernandadams/box-powershell-automations/issues).

## License

The MIT License (MIT)

Copyright (c) 2020 Kyle Adams

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
