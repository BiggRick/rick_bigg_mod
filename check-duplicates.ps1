# Get working directory (for relative paths)
$root = (Get-Location).Path

# Recursively scan all *.tp* files
$files = Get-ChildItem -Recurse -Filter *.tp*

# Hashtable: key = extracted string, value = list of objects { File, Count, Type }
$result = @{}

foreach ($file in $files) {
    $relative = Resolve-Path -Relative $file.FullName
    $lines = Get-Content $file.FullName

    foreach ($line in $lines) {

        $type = $null
        $item = $null

        # COPY "path/file.itm"
        if ($line -match 'COPY\s+"([^"]+)"') {
            $item = $matches[1].Split('/')[-1]
            $type = "COPY"
        }

        # SAY NAME2 "Some Name"
        elseif ($line -match 'SAY\s+NAME2\s+"([^"]+)"') {
            $item = $matches[1]
            $type = "SAY NAME2"
        }

        if (-not $type) { continue }

        if (-not $result.ContainsKey($item)) {
            $result[$item] = @()
        }

        $entry = $result[$item] | Where-Object { $_.File -eq $relative -and $_.Type -eq $type }

        if ($entry) {
            $entry.Count++
        } else {
            $result[$item] += [PSCustomObject]@{
                File  = $relative
                Count = 1
                Type  = $type
            }
        }
    }
}

function Print-Section($title, $type) {
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan

    $keys = $result.Keys |
        Where-Object { ($result[$_] | Where-Object { $_.Type -eq $type } | Measure-Object Count -Sum | Select-Object -ExpandProperty Sum) -gt 1 } |
        Sort-Object

    foreach ($key in $keys) {

        $entries = $result[$key] | Where-Object { $_.Type -eq $type }

        $details = ($entries |
            Sort-Object File |
            ForEach-Object { "$($_.Count)x in $($_.File)" }
        ) -join " and "

        Write-Host ""
        Write-Host ("{0}" -f $key) -ForegroundColor Red
        Write-Host ("    " + $details) -ForegroundColor Green
    }
}

Print-Section "duplicate COPY" "COPY"
Print-Section "duplicate SAY NAME2" "SAY NAME2"

Read-Host -Prompt "Press Enter to continue"

