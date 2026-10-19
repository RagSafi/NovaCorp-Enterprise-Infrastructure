NovaCorp – Enterprise IT Infrastructure

Project Overview

NovaCorp is a hands-on enterprise IT infrastructure lab built using Windows Server and Active Directory. The project demonstrates centralized identity management, department-based organizational structure, security groups, automated employee provisioning with PowerShell, and shared-folder permission configuration.

The lab represents a small enterprise environment with three departments: IT, HR, and Finance.

Environment

Windows Server 2025 Datacenter Evaluation

Active Directory Domain Services (AD DS)

Windows PowerShell

Active Directory PowerShell module

VirtualBox

CSV-based employee data

NTFS folder permissions

Active Directory Structure

Domain: crop.example.com

Organizational Unit hierarchy:

crop.example.com
└── NovaCorp
    ├── IT
    ├── HR
    └── Finance

The organizational structure separates employee accounts by department and supports centralized administration.

Employee Accounts and Security Groups

The lab contains sample employee accounts assigned to department-specific security groups.

Department

Security Group

Sample Employee

IT

GG_IT_Staff

Sara Ahmed

HR

GG_HR_Staff

Noura Khalid

Finance

GG_Finance_Staff

Fahad Ali

Department security groups provide a centralized way to manage employee membership and are used when configuring access to department resources.

PowerShell Employee Provisioning Automation

Script: PowerShell/Create-Users.ps1

The employee provisioning script automates the creation of Active Directory accounts using employee information stored in:

data/CSV/Employees.csv

Instead of creating every employee account manually, an administrator can maintain employee records in the CSV file and run the PowerShell script to validate and process them.

Workflow

Read employee records from the CSV file.

Validate required fields and username format.

Detect duplicate usernames in the CSV.

Verify that the target department OU and security group exist.

Skip usernames that already exist in Active Directory.

Display a preview of the accounts planned for creation.

Require explicit confirmation before creating accounts.

Request a temporary password securely.

Create enabled Active Directory accounts in the appropriate department OUs.

Add each new employee to the corresponding department security group.

Report successful operations and errors.

Department Assignment

The script uses department configuration to determine the target OU and security group.

IT: OU=IT,OU=NovaCorp and GG_IT_Staff

HR: OU=HR,OU=NovaCorp and GG_HR_Staff

Finance: OU=Finance,OU=NovaCorp and GG_Finance_Staff

The script detects the domain distinguished name and DNS name automatically, reducing the need to hardcode domain-specific values.

Account Security

Temporary passwords are entered securely rather than stored in the CSV.

New accounts are configured to require a password change at first logon.

Existing usernames are skipped to reduce the risk of duplicate account creation.

Account creation requires explicit administrator confirmation.

Validation and account-creation errors are reported to support troubleshooting.

The script requires appropriate Active Directory permissions and an environment where the Active Directory PowerShell module is available. Its configured CSV path must also be accessible from the machine running the script.

Department Shared Folders

A dedicated lab directory was created on the Windows Server:

C:\NovaCorp-Lab

The directory contains separate folders for departmental resources:

C:\NovaCorp-Lab
├── IT-Shared
├── HR-Shared
└── Finance-Shared

Permission Configuration

Department security groups are used when configuring NTFS permissions for shared folders.

GG_IT_Staff — IT department

GG_HR_Staff — HR department

GG_Finance_Staff — Finance department

The IT security group was configured with Modify permission on IT-Shared. An IT-Test.txt file was also created to support permission inspection.

Folder permission configuration and Active Directory group membership are separate parts of the infrastructure. Effective access between departments has not been fully verified through employee sign-in and access-denial tests; therefore, complete departmental isolation is not claimed as a validated result.

Validation and Test Results

The following results reflect the lab activities and checks performed:

Three sample employee accounts were created and enabled.

Department security-group membership was verified.

An existing administrator/lab account was preserved.

The PowerShell provisioning workflow includes validation, preview, and explicit confirmation.

Department shared folders were created.

The IT security group's Modify permission was configured on IT-Shared.

A test file was created for permission inspection.

Project documentation and evidence are organized in the project directory.

Project Structure

NovaCorp-Enterprise-Infrastructure/
├── README.md
├── PowerShell/
│   └── Create-Users.ps1
├── data/
│   └── CSV/
│       └── Employees.csv
└── Evidence/

This structure reflects the project folders and filenames identified during setup. Additional files, such as architecture diagrams, can be added when their actual filenames and locations are confirmed.

Security Considerations

Run provisioning scripts only with authorized Active Directory permissions.

Review the planned account-creation list before confirming execution.

Do not store passwords in CSV files or commit credentials to GitHub.

Use a dedicated lab directory for testing file operations.

Review inherited NTFS permissions before claiming that department folders are isolated.

Verify access with representative employee accounts before using the configuration in a production environment.

Skills Demonstrated

Windows Server administration

Active Directory Domain Services

Organizational Unit design

User and group administration

PowerShell scripting and automation

CSV data validation and processing

NTFS permissions

Basic identity and access management

Technical documentation and validation

Project Scope

NovaCorp is a local enterprise infrastructure lab intended to demonstrate Active Directory administration and employee provisioning automation. It is an educational portfolio project, not a production-ready deployment.

Future Improvements

Validate effective folder access using representative department accounts.

Add automated reporting for provisioning outcomes.

Expand error handling and automated test coverage.

Document the execution process with screenshots and architecture diagrams.