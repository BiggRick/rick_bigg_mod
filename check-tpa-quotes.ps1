param(
    [string]$Path = "lib",
    [string]$OutputPath = "..\weidu_external\traify",
    [string[]]$Files
)

$root = (Get-Location).Path
$target = Join-Path $root $Path
$weidu = Join-Path $root "..\weidu"
$output = Join-Path $root $OutputPath

if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    Write-Error "TPA directory not found: $target"
    exit 2
}

if (-not (Test-Path -LiteralPath $weidu -PathType Leaf)) {
    $weidu = "$weidu.exe"
}

if (-not (Test-Path -LiteralPath $weidu -PathType Leaf)) {
    Write-Error "WeiDU executable not found: $weidu"
    exit 2
}

$failedFiles = @()
if ($Files) {
    $tpaFiles = @(
        foreach ($file in $Files) {
            $resolvedFile = Resolve-Path -LiteralPath $file -ErrorAction Stop
            if ((Get-Item -LiteralPath $resolvedFile).Extension -ne ".tpa") {
                Write-Error "Not a TPA file: $file"
                exit 2
            }
            Get-Item -LiteralPath $resolvedFile
        }
    )
}
else {
    $tpaFiles = Get-ChildItem -LiteralPath $target -Recurse -Filter *.tpa -File
}

$maxJobs = [Math]::Ceiling([Environment]::ProcessorCount * 0.75)
$jobs = @()
$pendingFiles = [System.Collections.Queue]::new()
foreach ($item in $tpaFiles) {
    $pendingFiles.Enqueue($item.FullName)
}

while ($pendingFiles.Count -gt 0 -or $jobs.Count -gt 0) {
    while ($pendingFiles.Count -gt 0 -and $jobs.Count -lt $maxJobs) {
        $filePath = $pendingFiles.Dequeue()
        $jobs += [PSCustomObject]@{
            FilePath = $filePath
            Job = Start-Job -ArgumentList $weidu, $filePath, $output -ScriptBlock {
                param($weiduPath, $filePath, $outputPath)

                $ErrorActionPreference = "Continue"
                $PSNativeCommandUseErrorActionPreference = $false
                $logFile = [System.IO.Path]::GetTempFileName()
                & $weiduPath --traify $filePath --out $outputPath --nogame *> $logFile
                $exitCode = $LASTEXITCODE
                $weiduOutput = Get-Content -LiteralPath $logFile -Raw
                Remove-Item -LiteralPath $logFile

                [PSCustomObject]@{
                    File = $filePath
                    ExitCode = $exitCode
                    Succeeded = $exitCode -eq 0 -and $weiduOutput -notmatch '(?m)^(FATAL ERROR|.*PARSE ERROR|ERROR: parsing|ERROR: problem tra-ifying)'
                    Output = $weiduOutput
                }
            }
        }
    }

    $completedJobs = $jobs | Where-Object { $_.Job.State -ne "Running" }
    if (-not $completedJobs) {
        Start-Sleep -Milliseconds 100
        continue
    }

    foreach ($jobInfo in $completedJobs) {
        $result = @(Receive-Job -Job $jobInfo.Job) |
            Where-Object { $_.PSObject.Properties.Name -contains "Succeeded" } |
            Select-Object -Last 1

        if (-not $result -or -not $result.Succeeded) {
            $failedFiles += Resolve-Path -Relative $jobInfo.FilePath
            if ($result) {
                Write-Host $result.Output
            }
        }
        Remove-Job -Job $jobInfo.Job
    }
    $jobs = @($jobs | Where-Object { $_.Job.State -eq "Running" })
}

if ($failedFiles.Count -eq 0) {
    Write-Host "WeiDU validated $($tpaFiles.Count) TPA file(s) successfully using up to $maxJobs parallel jobs."
    exit 0
}

Write-Host "WeiDU failed to parse the following TPA files:" -ForegroundColor Red
foreach ($failedFile in $failedFiles) {
    Write-Host $failedFile
}

exit 1
