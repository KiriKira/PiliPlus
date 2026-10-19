param(
    [string]$Arg = ''
)

try {
    $CustomizationsPatch = 'lib/scripts/piliplus_foldable_customizations.patch'
    git apply --check --verbose $CustomizationsPatch
    if ($LASTEXITCODE -eq 0) {
        git apply --verbose $CustomizationsPatch
        if ($LASTEXITCODE -ne 0) {
            throw "failed to apply $CustomizationsPatch"
        }
        Write-Host "$CustomizationsPatch applied"
    }
    else {
        Write-Host "Forward patch check failed; checking whether it is already applied"
        git apply --reverse --check --verbose $CustomizationsPatch
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$CustomizationsPatch already applied"
        }
        else {
            throw "$CustomizationsPatch does not apply cleanly"
        }
    }

    $baseVersionName = $null

    $versionCode = if ($env:PILI_VERSION_CODE) {
        [int]$env:PILI_VERSION_CODE
    } else {
        [int](git rev-list --count HEAD).Trim()
    }

    $commitHash = (git rev-parse HEAD).Trim()

    $updatedContent = foreach ($line in (Get-Content -Path 'pubspec.yaml' -Encoding UTF8)) {
        if ($line -match '^\s*version:\s*([\d\.]+)') {
            $baseVersionName = $matches[1]
            "version: $baseVersionName+$versionCode"
        }
        else {
            $line
        }
    }

    if ($null -eq $baseVersionName) {
        throw 'version not found'
    }

    $updatedContent | Set-Content -Path 'pubspec.yaml' -Encoding UTF8

    $releaseVersionName = if ($env:PILI_RELEASE_VERSION_NAME) {
        $env:PILI_RELEASE_VERSION_NAME
    } else {
        $baseVersionName
    }

    $buildTime = [int]([DateTimeOffset]::Now.ToUnixTimeSeconds())

    $data = @{
        'pili.name' = $releaseVersionName
        'pili.code' = $versionCode
        'pili.hash' = $commitHash
        'pili.time' = $buildTime
    }

    $data | ConvertTo-Json -Compress | Out-File 'pili_release.json' -Encoding UTF8

    Add-Content -Path $env:GITHUB_ENV -Value "version=$releaseVersionName+$versionCode"
}
catch {
    Write-Error "Prebuild Error: $($_.Exception.Message)"
    exit 1
}
