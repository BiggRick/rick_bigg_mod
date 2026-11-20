param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $InputDirectory,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $CreatureFiles
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $InputDirectory -PathType Container)) {
    throw "Creature XML directory does not exist: $InputDirectory"
}

$resolvedDirectory = (Resolve-Path -LiteralPath $InputDirectory).Path
$creatureNames = [System.Collections.Generic.List[string]]::new()
$seenCreatures = @{}

foreach ($entry in $CreatureFiles) {
    if ($entry.Trim() -match '^(?i:override)$') {
        continue
    }

    $matches = [regex]::Matches($entry, '(?i)[A-Z0-9#_-]+\.CRE')
    if ($matches.Count -eq 0) {
        throw "Could not find a .CRE resource name in: $entry"
    }

    foreach ($match in $matches) {
        $creatureName = $match.Value.ToUpperInvariant()
        if (-not $seenCreatures.ContainsKey($creatureName)) {
            $seenCreatures[$creatureName] = $true
            $creatureNames.Add($creatureName)
        }
    }
}

if ($creatureNames.Count -eq 0) {
    throw 'No creature resource names were supplied.'
}

$slotLabels = @{
    Helmet      = 'Elmo'
    Armor       = 'Armatura'
    Shield      = 'Scudo'
    Gloves      = 'Guanti'
    Left_ring   = 'Anello sinistro'
    Right_ring  = 'Anello destro'
    Amulet      = 'Amuleto'
    Belt        = 'Cintura'
    Boots       = 'Stivali'
    Weapon      = 'Arma'
    Quiver      = 'Faretra'
    Cloak       = 'Mantello'
    Quick_item  = 'Oggetto rapido'
    Inventory   = 'Inventario'
}

$itemNameCache = @{}
$itemSlotNodes = "//*[local-name()='Helmet' or local-name()='Armor' or " +
    "local-name()='Shield' or local-name()='Gloves' or " +
    "local-name()='Left_ring' or local-name()='Right_ring' or " +
    "local-name()='Amulet' or local-name()='Belt' or local-name()='Boots' or " +
    "local-name()='Weapon' or local-name()='Quiver' or local-name()='Cloak' or " +
    "local-name()='Quick_item' or local-name()='Inventory']"

foreach ($creatureName in $creatureNames) {
    $creaturePath = Join-Path $resolvedDirectory "$creatureName.xml"
    if (-not (Test-Path -LiteralPath $creaturePath -PathType Leaf)) {
        throw "Creature XML file not found: $creaturePath"
    }

    $creatureDocument = [System.Xml.XmlDocument]::new()
    $creatureDocument.Load((Resolve-Path -LiteralPath $creaturePath).Path)

    $itemRecords = $creatureDocument.SelectNodes(
        "//*[local-name()='Item' and @size='20' and *[local-name()='Item']]"
    )
    $equipmentSlots = $creatureDocument.SelectNodes($itemSlotNodes)

    foreach ($record in $itemRecords) {
        $resrefNode = $record.SelectSingleNode("./*[local-name()='Item']")
        $resref = $resrefNode.InnerText.Trim().ToUpperInvariant()
        if ($resref -notmatch '^[A-Z0-9#_-]+\.ITM$') {
            throw "Invalid item resref in ${creatureName}: $($resrefNode.InnerText)"
        }

        $itemIdText = $record.GetAttribute('id')
        $itemId = 0
        if (-not [int]::TryParse($itemIdText, [ref] $itemId)) {
            throw "Invalid item record ID in ${creatureName} for ${resref}: $itemIdText"
        }

        $occupiedSlots = [System.Collections.Generic.List[string]]::new()
        foreach ($slot in $equipmentSlots) {
            $slotItemIdText = $slot.GetAttribute('value')
            if ([string]::IsNullOrWhiteSpace($slotItemIdText)) {
                continue
            }

            $slotItemId = [long] 0
            if ($slotItemIdText -match '^0x([0-9A-Fa-f]+)$') {
                $slotItemId = [Convert]::ToInt64($Matches[1], 16)
            }
            elseif (-not [long]::TryParse($slotItemIdText, [ref] $slotItemId)) {
                continue
            }

            if ($slotItemId -ne $itemId) {
                continue
            }

            $slotName = $slotLabels[$slot.LocalName]
            if ($slot.LocalName -in @('Weapon', 'Quiver', 'Quick_item', 'Inventory')) {
                $slotIndex = $slot.GetAttribute('id')
                if (-not [string]::IsNullOrWhiteSpace($slotIndex)) {
                    $slotName = "$slotName $slotIndex"
                }
            }
            $occupiedSlots.Add($slotName)
        }

        if ($occupiedSlots.Count -eq 0) {
            $slotDescription = 'Inventario (non assegnato a uno slot)'
        }
        else {
            $slotDescription = $occupiedSlots -join '; '
        }

        if (-not $itemNameCache.ContainsKey($resref)) {
            $displayName = $resref
            $itemPath = Join-Path $resolvedDirectory "$resref.xml"
            if (Test-Path -LiteralPath $itemPath -PathType Leaf) {
                $itemDocument = [System.Xml.XmlDocument]::new()
                $itemDocument.Load((Resolve-Path -LiteralPath $itemPath).Path)
                foreach ($nameElement in @('Identified_name', 'General_name')) {
                    $nameNode = $itemDocument.SelectSingleNode(
                        "//*[local-name()='$nameElement']"
                    )
                    if ($null -ne $nameNode -and
                        -not [string]::IsNullOrWhiteSpace($nameNode.InnerText) -and
                        $nameNode.InnerText -notmatch '^No such index$') {
                        $displayName = $nameNode.InnerText.Trim()
                        break
                    }
                }
            }
            $itemNameCache[$resref] = $displayName
        }

        [pscustomobject] @{
            Creatura = $creatureName
            Oggetto  = $resref
            Nome     = $itemNameCache[$resref]
            Slot     = $slotDescription
        }
    }
}
