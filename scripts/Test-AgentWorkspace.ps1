[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

function Invoke-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )

    Write-Host ""
    Write-Host "=== $Name ===" -ForegroundColor Cyan

    $Global:LASTEXITCODE = 0
    & $Command
    $ExitCode = $LASTEXITCODE

    if ($null -eq $ExitCode) {
        $ExitCode = 0
    }

    $Results.Add([PSCustomObject]@{
        Check = $Name
        ExitCode = $ExitCode
        Passed = ($ExitCode -eq 0)
    })

    if ($ExitCode -eq 0) {
        Write-Host "PASS: $Name" -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: $Name (exit $ExitCode)" -ForegroundColor Red
    }
}

try {
    Invoke-Check "Git diff whitespace check" { git diff --check }

    $PackageJson = Join-Path $Root "package.json"

    if (Test-Path $PackageJson) {
        try {
            $Package = Get-Content $PackageJson -Raw | ConvertFrom-Json
            $Scripts = $Package.scripts

            foreach ($Candidate in @("format:check", "lint", "typecheck", "type-check", "test", "build")) {
                if ($Scripts -and $Scripts.PSObject.Properties.Name -contains $Candidate) {
                    $Name = "npm run $Candidate"
                    Invoke-Check $Name { npm run $Candidate }
                }
            }
        }
        catch {
            Write-Warning "Could not parse package.json: $($_.Exception.Message)"
        }
    }

    if (Test-Path (Join-Path $Root "pyproject.toml")) {
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Invoke-Check "Python compile check" {
                python -m compileall -q .
            }
        }
    }

    Write-Host ""
    Write-Host "=== Validation summary ===" -ForegroundColor Cyan
    $Results | Format-Table -AutoSize

    $Failures = @($Results | Where-Object { -not $_.Passed })

    if ($Failures.Count -gt 0) {
        Write-Error "$($Failures.Count) validation check(s) failed."
        exit 1
    }

    Write-Host "All detected validation checks passed." -ForegroundColor Green
    exit 0
}
finally {
    Pop-Location
}
