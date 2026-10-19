$CsvPath = "\\VBOXSVR\NovaCorp-Enterprise-Infrastructure\data\CSV\Employees.csv"

# Detect the actual domain automatically
$Domain = Get-ADDomain
$DomainDN = $Domain.DistinguishedName
$UPNSuffix = $Domain.DNSRoot

# Department configuration
$Departments = @{
    IT = @{
        OU    = "OU=IT,OU=NovaCorp,$DomainDN"
        Group = "GG_IT_Staff"
    }
    HR = @{
        OU    = "OU=HR,OU=NovaCorp,$DomainDN"
        Group = "GG_HR_Staff"
    }
    Finance = @{
        OU    = "OU=Finance,OU=NovaCorp,$DomainDN"
        Group = "GG_Finance_Staff"
    }
}

# Import employees
if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

$Employees = @(Import-Csv -Path $CsvPath)

if ($Employees.Count -eq 0) {
    throw "CSV contains no employees."
}

$RequiredColumns = @(
    "FirstName", "LastName", "Username", "Department", "Title"
)

foreach ($Column in $RequiredColumns) {
    if ($Column -notin $Employees[0].PSObject.Properties.Name) {
        throw "Missing CSV column: $Column"
    }
}

# Validate and build creation plan
$Plan = @()
$SeenUsernames = @{}

foreach ($Employee in $Employees) {
    $FirstName = ([string]$Employee.FirstName).Trim()
    $LastName  = ([string]$Employee.LastName).Trim()
    $Username  = ([string]$Employee.Username).Trim()
    $Department = ([string]$Employee.Department).Trim()
    $Title = ([string]$Employee.Title).Trim()

    if (-not $FirstName -or -not $LastName -or
        -not $Username -or -not $Department -or -not $Title) {
        Write-Warning "Skipped row: required fields are missing."
        continue
    }

    if ($Username -notmatch '^[a-zA-Z0-9._-]{1,20}$') {
        Write-Warning "Invalid username: $Username"
        continue
    }

    if ($SeenUsernames.ContainsKey($Username.ToLowerInvariant())) {
        Write-Warning "Duplicate username in CSV: $Username"
        continue
    }

    $SeenUsernames[$Username.ToLowerInvariant()] = $true

    if (-not $Departments.ContainsKey($Department)) {
        Write-Warning "Unknown department: $Department"
        continue
    }

    $Config = $Departments[$Department]

    $ExistingOU = Get-ADOrganizationalUnit `
        -Identity $Config.OU -ErrorAction SilentlyContinue

    $ExistingGroup = Get-ADGroup `
        -Filter "SamAccountName -eq '$($Config.Group)'" `
        -ErrorAction SilentlyContinue

    if (-not $ExistingOU -or -not $ExistingGroup) {
        Write-Warning "OU or group missing for department: $Department"
        continue
    }

    $ExistingUser = Get-ADUser `
        -Filter "SamAccountName -eq '$Username'" `
        -ErrorAction SilentlyContinue

    if ($ExistingUser) {
        Write-Warning "User already exists: $Username"
        continue
    }

    $Plan += [PSCustomObject]@{
        Username   = $Username
        FullName   = "$FirstName $LastName"
        FirstName  = $FirstName
        LastName   = $LastName
        Department = $Department
        Title      = $Title
        OU         = $Config.OU
        Group      = $Config.Group
    }
}

# Preview
Write-Host "`nNOVACORP - ACCOUNT CREATION PREVIEW" -ForegroundColor Cyan
$Plan | Format-Table Username, FullName, Department, Group -AutoSize
Write-Host "Valid accounts to create: $($Plan.Count)"

if ($Plan.Count -eq 0) {
    Write-Warning "No valid new accounts. Nothing was created."
    return
}

# Require explicit confirmation
$Confirm = Read-Host "Type CREATE to create these accounts"
if ($Confirm -cne "CREATE") {
    Write-Host "Cancelled. No accounts were created." -ForegroundColor Yellow
    return
}

# Secure temporary password; never stored in CSV
$TemporaryPassword = Read-Host `
    "Enter a temporary password that meets domain policy" `
    -AsSecureString

# Create users and add them to their department groups
foreach ($Employee in $Plan) {
    try {
        # Recheck immediately before creation
        $ExistingUser = Get-ADUser `
            -Filter "SamAccountName -eq '$($Employee.Username)'" `
            -ErrorAction SilentlyContinue

        if ($ExistingUser) {
            Write-Warning "$($Employee.Username) already exists. Skipped."
            continue
        }

        New-ADUser `
            -Name $Employee.FullName `
            -GivenName $Employee.FirstName `
            -Surname $Employee.LastName `
            -SamAccountName $Employee.Username `
            -UserPrincipalName "$($Employee.Username)@$UPNSuffix" `
            -Title $Employee.Title `
            -Department $Employee.Department `
            -Path $Employee.OU `
            -AccountPassword $TemporaryPassword `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        Add-ADGroupMember `
            -Identity $Employee.Group `
            -Members $Employee.Username `
            -ErrorAction Stop

        Write-Host "SUCCESS: $($Employee.Username) -> $($Employee.Group)" `
            -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed for $($Employee.Username): $($_.Exception.Message)"
    }
}

Write-Host "`nAccount creation process finished."
Write-Host "NovaCorp employee provisioning completed." -ForegroundColor Cyan
