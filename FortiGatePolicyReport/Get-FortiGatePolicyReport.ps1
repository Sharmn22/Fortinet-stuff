#requires -Version 7.0
<#
    Get-FortiGatePolicyReport.ps1

    Connects to a FortiGate's REST API, pulls all firewall policies,
    and renders them into a self-contained HTML report.

    Requires PowerShell 7+ (uses Invoke-RestMethod -SkipCertificateCheck).
#>

# ----------------------------------------------------------------------------
# Configuration - edit these for your environment
# ----------------------------------------------------------------------------
$FortiGateIP   = "192.168.1.99"          # FortiGate management IP / hostname
$FortiGatePort = 8443                    # HTTPS admin/API port
$ApiUser       = "PASTE-YOUR-API-ADMIN"   # API admin username (for reference/logging only)
$ApiKey        = "PASTE-YOUR-API-KEY"
$Vdom          = "root"                 # VDOM to query (this FortiGate has VDOMs disabled)

# ----------------------------------------------------------------------------
# Call the FortiGate REST API
# ----------------------------------------------------------------------------
$uri = "https://${FortiGateIP}:${FortiGatePort}/api/v2/cmdb/firewall/policy?vdom=$Vdom"

Write-Host "Connecting to FortiGate at $FortiGateIP`:$FortiGatePort as $ApiUser ..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $uri `
        -Headers @{ Authorization = "Bearer $ApiKey" } `
        -Method Get `
        -SkipCertificateCheck `
        -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve firewall policies from $FortiGateIP`:$FortiGatePort. $($_.Exception.Message)"
    exit 1
}

if (-not $response.results) {
    Write-Error "No policies returned. Check the API key, admin trusted-host restrictions, and VDOM name."
    exit 1
}

Write-Host "Retrieved $($response.results.Count) firewall policies." -ForegroundColor Green

# ----------------------------------------------------------------------------
# Helper: flatten a FortiGate name-object array (e.g. srcaddr[].name) into a string
# ----------------------------------------------------------------------------
function Join-FgNames {
    param($NameObjects)
    if (-not $NameObjects) { return "" }
    return ($NameObjects | ForEach-Object { $_.name }) -join ", "
}

# ----------------------------------------------------------------------------
# Transform each policy into a report row
# ----------------------------------------------------------------------------
$rows = foreach ($policy in $response.results) {

    # IP Pool NAT
    if ($policy.ippool -eq "enable") {
        $ipPoolNat = Join-FgNames $policy.poolname
        if (-not $ipPoolNat) { $ipPoolNat = "Enabled" }
    }
    else {
        $ipPoolNat = "Disabled"
    }

    # Security profiles - either a profile-group, or individual profiles
    $profileParts = @()
    if ($policy.'profile-group') {
        $profileParts += "Group: $($policy.'profile-group')"
    }
    else {
        if ($policy.'av-profile')          { $profileParts += "AV: $($policy.'av-profile')" }
        if ($policy.'webfilter-profile')   { $profileParts += "Web: $($policy.'webfilter-profile')" }
        if ($policy.'dnsfilter-profile')   { $profileParts += "DNS: $($policy.'dnsfilter-profile')" }
        if ($policy.'ips-sensor')          { $profileParts += "IPS: $($policy.'ips-sensor')" }
        if ($policy.'application-list')    { $profileParts += "App: $($policy.'application-list')" }
        if ($policy.'ssl-ssh-profile')     { $profileParts += "SSL: $($policy.'ssl-ssh-profile')" }
    }
    $securityProfiles = if ($profileParts.Count -gt 0) { $profileParts -join "<br>" } else { "None" }

    [PSCustomObject]@{
        ID               = $policy.policyid
        Name             = if ($policy.name) { $policy.name } else { "(unnamed)" }
        From             = Join-FgNames $policy.srcintf
        To               = Join-FgNames $policy.dstintf
        Source           = Join-FgNames $policy.srcaddr
        Destination      = Join-FgNames $policy.dstaddr
        Schedule         = $policy.schedule
        Service          = Join-FgNames $policy.service
        Action           = $policy.action
        IPPoolNAT        = $ipPoolNat
        SecurityProfiles = $securityProfiles
        Log              = $policy.logtraffic
        Status           = $policy.status
    }
}

# ----------------------------------------------------------------------------
# Build the HTML report
# ----------------------------------------------------------------------------
$generatedOn = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$tableRows = foreach ($row in $rows) {

    $rowClass = if ($row.Status -eq "disable") { "disabled-row" } else { "" }

    $actionClass = switch ($row.Action) {
        "accept" { "action-accept" }
        "deny"   { "action-deny" }
        default  { "" }
    }

    $statusBadge = if ($row.Status -eq "disable") {
        '<span class="badge badge-disabled">DISABLED</span>'
    } else {
        '<span class="badge badge-enabled">Enabled</span>'
    }

    @"
    <tr class="$rowClass">
        <td>$($row.ID)</td>
        <td>$($row.Name) $statusBadge</td>
        <td>$($row.From)</td>
        <td>$($row.To)</td>
        <td>$($row.Source)</td>
        <td>$($row.Destination)</td>
        <td>$($row.Schedule)</td>
        <td>$($row.Service)</td>
        <td class="$actionClass">$($row.Action)</td>
        <td>$($row.IPPoolNAT)</td>
        <td>$($row.SecurityProfiles)</td>
        <td>$($row.Log)</td>
    </tr>
"@
}

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>FortiGate Firewall Policy Report</title>
<style>
    body {
        font-family: Segoe UI, Arial, sans-serif;
        background-color: #f4f6f8;
        color: #1a1a1a;
        margin: 0;
        padding: 20px;
    }
    h1 {
        color: #d02128;
        margin-bottom: 4px;
    }
    .meta {
        color: #555;
        margin-bottom: 20px;
        font-size: 0.9em;
    }
    table {
        border-collapse: collapse;
        width: 100%;
        background-color: #fff;
        box-shadow: 0 1px 4px rgba(0,0,0,0.15);
        font-size: 0.85em;
    }
    th, td {
        border: 1px solid #ddd;
        padding: 8px 10px;
        text-align: left;
        vertical-align: top;
    }
    th {
        background-color: #2b2f38;
        color: #fff;
        position: sticky;
        top: 0;
        cursor: pointer;
        user-select: none;
    }
    th:hover {
        background-color: #40465a;
    }
    tr:nth-child(even) {
        background-color: #f9f9f9;
    }
    tr:hover {
        background-color: #eef6ff;
    }
    tr.disabled-row {
        opacity: 0.55;
        font-style: italic;
    }
    .action-accept {
        color: #1a7a1a;
        font-weight: bold;
    }
    .action-deny {
        color: #c0392b;
        font-weight: bold;
    }
    .badge {
        display: inline-block;
        font-size: 0.7em;
        font-weight: bold;
        padding: 2px 6px;
        border-radius: 4px;
        margin-left: 6px;
    }
    .badge-disabled {
        background-color: #c0392b;
        color: #fff;
    }
    .badge-enabled {
        display: none;
    }
    .footer {
        margin-top: 16px;
        font-size: 0.8em;
        color: #888;
    }
</style>
<script>
    function sortTable(colIndex) {
        const table = document.getElementById("policyTable");
        const tbody = table.tBodies[0];
        const rows = Array.from(tbody.rows);
        const asc = table.dataset.sortCol == colIndex && table.dataset.sortDir !== "asc";
        rows.sort((a, b) => {
            const aText = a.cells[colIndex].innerText.trim().toLowerCase();
            const bText = b.cells[colIndex].innerText.trim().toLowerCase();
            const aNum = parseFloat(aText), bNum = parseFloat(bText);
            if (!isNaN(aNum) && !isNaN(bNum)) return asc ? aNum - bNum : bNum - aNum;
            return asc ? aText.localeCompare(bText) : bText.localeCompare(aText);
        });
        rows.forEach(r => tbody.appendChild(r));
        table.dataset.sortCol = colIndex;
        table.dataset.sortDir = asc ? "asc" : "desc";
    }
</script>
</head>
<body>
    <h1>FortiGate Firewall Policy Report</h1>
    <div class="meta">
        FortiGate: $FortiGateIP`:$FortiGatePort &nbsp;|&nbsp; VDOM: $Vdom &nbsp;|&nbsp;
        Generated: $generatedOn &nbsp;|&nbsp; Total policies: $($rows.Count)
    </div>
    <table id="policyTable">
        <thead>
            <tr>
                <th onclick="sortTable(0)">ID</th>
                <th onclick="sortTable(1)">Policy Name</th>
                <th onclick="sortTable(2)">From</th>
                <th onclick="sortTable(3)">To</th>
                <th onclick="sortTable(4)">Source</th>
                <th onclick="sortTable(5)">Destination</th>
                <th onclick="sortTable(6)">Schedule</th>
                <th onclick="sortTable(7)">Service</th>
                <th onclick="sortTable(8)">Action</th>
                <th onclick="sortTable(9)">IP Pool NAT</th>
                <th onclick="sortTable(10)">Security Profiles</th>
                <th onclick="sortTable(11)">Log</th>
            </tr>
        </thead>
        <tbody>
$($tableRows -join "`n")
        </tbody>
    </table>
    <div class="footer">Click a column header to sort. Disabled policies are shown greyed-out with a DISABLED badge.</div>
</body>
</html>
"@

# ----------------------------------------------------------------------------
# Save and open the report
# ----------------------------------------------------------------------------
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFile = Join-Path $PSScriptRoot "FortiGate-Policy-Report_$timestamp.html"

$html | Out-File -FilePath $outputFile -Encoding utf8

Write-Host "Report saved to: $outputFile" -ForegroundColor Green

Invoke-Item $outputFile
