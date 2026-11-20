[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [switch] $Force,

    [Parameter(ValueFromPipeline = $true)]
    [psobject] $InventoryRow
)

begin {
    $ErrorActionPreference = 'Stop'
    $rows = [System.Collections.Generic.List[object]]::new()
}

process {
    if ($null -ne $InventoryRow) {
        foreach ($property in 'Creatura', 'Oggetto', 'Nome', 'Slot') {
            if ($null -eq $InventoryRow.PSObject.Properties[$property]) {
                throw "Inventory row is missing required property: $property"
            }
        }
        $rows.Add($InventoryRow)
    }
}

end {
    if ($rows.Count -eq 0) {
        throw 'No inventory rows were provided; the workbook was not created.'
    }

    Add-Type -AssemblyName System.IO.Compression

    $destination = [System.IO.Path]::GetFullPath($OutputPath)
    $destinationDirectory = [System.IO.Path]::GetDirectoryName($destination)
    if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
        throw "Output directory does not exist: $destinationDirectory"
    }
    if ([System.IO.Path]::GetExtension($destination) -ne '.xlsx') {
        throw "Output path must end in .xlsx: $destination"
    }
    if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        throw "Output already exists; use -Force to replace it: $destination"
    }

    function ConvertTo-XmlText([string] $Value) {
        return [System.Security.SecurityElement]::Escape($Value)
    }

    function New-TextCell([string] $Column, [int] $Row, [string] $Value, [int] $Style = 0) {
        $escapedValue = ConvertTo-XmlText $Value
        return "<c r=`"$Column$Row`" t=`"inlineStr`" s=`"$Style`"><is><t xml:space=`"preserve`">$escapedValue</t></is></c>"
    }

    function ConvertTo-ExcelColumnName([int] $ColumnNumber) {
        $columnName = ''
        while ($ColumnNumber -gt 0) {
            $remainder = ($ColumnNumber - 1) % 26
            $columnName = [string] [char] (65 + $remainder) + $columnName
            $ColumnNumber = [math]::Floor(($ColumnNumber - 1) / 26)
        }
        return $columnName
    }

    function New-WorksheetXml(
        [string[]] $Headers,
        [string[]] $Fields,
        [object[]] $Data,
        [int[]] $Widths,
        [string] $NumericField,
        [bool] $FreezeFirstColumn = $false
    ) {
        $xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        $xml += '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        if ($FreezeFirstColumn) {
            $xml += '<sheetViews><sheetView workbookViewId="0"><pane xSplit="1" ySplit="1" topLeftCell="B2" activePane="bottomRight" state="frozen"/></sheetView></sheetViews><cols>'
        }
        else {
            $xml += '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols>'
        }
        for ($index = 0; $index -lt $Widths.Count; $index++) {
            $columnNumber = $index + 1
            $xml += "<col min=`"$columnNumber`" max=`"$columnNumber`" width=`"$($Widths[$index])`" customWidth=`"1`"/>"
        }
        $xml += '</cols><sheetData><row r="1">'
        for ($index = 0; $index -lt $Headers.Count; $index++) {
            $column = ConvertTo-ExcelColumnName ($index + 1)
            $xml += New-TextCell $column 1 $Headers[$index] 1
        }
        $xml += '</row>'

        $rowNumber = 2
        foreach ($dataRow in $Data) {
            $xml += "<row r=`"$rowNumber`">"
            for ($index = 0; $index -lt $Headers.Count; $index++) {
                $field = $Fields[$index]
                $column = ConvertTo-ExcelColumnName ($index + 1)
                $value = [string] $dataRow.PSObject.Properties[$field].Value
                if ($field -eq $NumericField) {
                    $number = 0
                    if (-not [int]::TryParse($value, [ref] $number)) {
                        throw "Expected a numeric value for $field in row $rowNumber."
                    }
                    $xml += "<c r=`"$column$rowNumber`"><v>$number</v></c>"
                }
                else {
                    $xml += New-TextCell $column $rowNumber $value
                }
            }
            $xml += '</row>'
            $rowNumber++
        }

        $lastRow = $rowNumber - 1
        $lastColumn = ConvertTo-ExcelColumnName $Headers.Count
        $xml += '</sheetData>'
        $xml += "<autoFilter ref=`"A1:$lastColumn$lastRow`"/></worksheet>"
        return $xml
    }

    $creatureOrder = [System.Collections.Generic.List[string]]::new()
    $creatureRows = @{}
    $itemOrder = [System.Collections.Generic.List[string]]::new()
    $seenItems = @{}
    foreach ($row in $rows) {
        if (-not $creatureRows.ContainsKey($row.Creatura)) {
            $creatureOrder.Add($row.Creatura)
            $creatureRows[$row.Creatura] = [System.Collections.Generic.List[object]]::new()
        }
        $creatureRows[$row.Creatura].Add($row)

        if (-not $seenItems.ContainsKey($row.Oggetto)) {
            $seenItems[$row.Oggetto] = $true
            $itemOrder.Add($row.Oggetto)
        }
    }

    $matrixRows = [System.Collections.Generic.List[object]]::new()
    $summaryRows = [System.Collections.Generic.List[object]]::new()
    foreach ($creature in $creatureOrder) {
        $itemsForCreature = $creatureRows[$creature]
        $items = [System.Collections.Generic.List[string]]::new()
        foreach ($row in $itemsForCreature) {
            $items.Add("$($row.Oggetto) - $($row.Nome) [$($row.Slot)]")
        }
        $summaryRows.Add([pscustomobject] @{
            Creatura = $creature
            Oggetti  = $items -join '; '
            Numero   = $itemsForCreature.Count
        })

        $matrixValues = [ordered] @{ Creatura = $creature }
        foreach ($itemRef in $itemOrder) {
            $matchingItems = @($itemsForCreature | Where-Object { $_.Oggetto -eq $itemRef })
            if ($matchingItems.Count -eq 0) {
                $matrixValues[$itemRef] = ''
            }
            else {
                $matrixValues[$itemRef] = (@($matchingItems | Select-Object -ExpandProperty Slot -Unique) -join '; ')
            }
        }
        $matrixRows.Add([pscustomobject] $matrixValues)
    }

    $matrixHeaders = [System.Collections.Generic.List[string]]::new()
    $matrixFields = [System.Collections.Generic.List[string]]::new()
    $matrixWidths = [System.Collections.Generic.List[int]]::new()
    $matrixHeaders.Add('Creatura (.CRE)')
    $matrixFields.Add('Creatura')
    $matrixWidths.Add(24)
    foreach ($itemRef in $itemOrder) {
        $matrixHeaders.Add($itemRef)
        $matrixFields.Add($itemRef)
        $matrixWidths.Add(20)
    }
    $matrixXml = New-WorksheetXml `
        -Headers $matrixHeaders.ToArray() `
        -Fields $matrixFields.ToArray() `
        -Data $matrixRows.ToArray() `
        -Widths $matrixWidths.ToArray() `
        -NumericField '' `
        -FreezeFirstColumn $true
    $detailXml = New-WorksheetXml `
        -Headers @('Creatura (.CRE)', 'Oggetto (.ITM)', 'Nome', 'Slot') `
        -Fields @('Creatura', 'Oggetto', 'Nome', 'Slot') `
        -Data $rows.ToArray() `
        -Widths @(22, 22, 32, 42) `
        -NumericField ''
    $summaryXml = New-WorksheetXml `
        -Headers @('Creatura (.CRE)', 'Oggetti e slot', 'Numero oggetti') `
        -Fields @('Creatura', 'Oggetti', 'Numero') `
        -Data $summaryRows.ToArray() `
        -Widths @(22, 100, 18) `
        -NumericField 'Numero'

    $contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
        '<Default Extension="xml" ContentType="application/xml"/>' +
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
        '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
        '<Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
        '</Types>'
    $packageRelationships = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
        '</Relationships>'
    $workbook = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
        '<sheets><sheet name="Matrice" sheetId="1" r:id="rId1"/><sheet name="Dettaglio" sheetId="2" r:id="rId2"/><sheet name="Riepilogo" sheetId="3" r:id="rId3"/></sheets></workbook>'
    $workbookRelationships = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>' +
        '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>' +
        '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
        '</Relationships>'
    $styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>' +
        '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>' +
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
        '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>' +
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>'

    $fileMode = if ($Force) {
        [System.IO.FileMode]::Create
    }
    else {
        [System.IO.FileMode]::CreateNew
    }
    $fileStream = [System.IO.File]::Open($destination, $fileMode, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new(
            $fileStream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false
        )
        try {
            $encoding = [System.Text.UTF8Encoding]::new($false)
            $entries = @(
                @{ Name = '[Content_Types].xml'; Content = $contentTypes },
                @{ Name = '_rels/.rels'; Content = $packageRelationships },
                @{ Name = 'xl/workbook.xml'; Content = $workbook },
                @{ Name = 'xl/_rels/workbook.xml.rels'; Content = $workbookRelationships },
                @{ Name = 'xl/styles.xml'; Content = $styles },
                @{ Name = 'xl/worksheets/sheet1.xml'; Content = $matrixXml },
                @{ Name = 'xl/worksheets/sheet2.xml'; Content = $detailXml },
                @{ Name = 'xl/worksheets/sheet3.xml'; Content = $summaryXml }
            )
            foreach ($entryDefinition in $entries) {
                $entry = $archive.CreateEntry($entryDefinition.Name)
                $writer = [System.IO.StreamWriter]::new($entry.Open(), $encoding)
                try {
                    $writer.Write($entryDefinition.Content)
                }
                finally {
                    $writer.Dispose()
                }
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $fileStream.Dispose()
    }

    [pscustomobject] @{
        FullName     = $destination
        CreatureCount = $summaryRows.Count
        ItemCount     = $rows.Count
    }
}
