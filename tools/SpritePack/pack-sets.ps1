#Requires -Version 5.1
<#
.SYNOPSIS
    Builds every .mset sprite set from the loose images under bin\.

.DESCRIPTION
    Sprites are grouped by what they are, not by which folder history
    left them in and not by which level happens to use them. Levels
    reuse each other's tiles - level 2 borrows doom1 from level 1 - so a
    set per level would need duplication or cross-references from the
    first day.

    Monsters, the hero and the weapons pack folder-for-folder, with
    frame order taken from the 2008 sprite lists beside them. Tiles are
    dealt out by the tables below: the first pattern that matches a name
    wins, and anything no pattern claims is packed into a leftovers set
    and reported, so nothing disappears quietly.

    The sets land in bin\sprites\. Nothing reads them yet - the engine
    still loads loose PNGs - so this changes nothing about the game.

.PARAMETER Bin
    The bin folder. Defaults to ..\..\bin relative to this script.

.PARAMETER Output
    Where the sets go. Defaults to <Bin>\sprites.

.PARAMETER Tool
    SpritePackCli.exe. Defaults to <Bin>\SpritePackCli.exe.

.EXAMPLE
    .\pack-sets.ps1
    .\pack-sets.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Bin,
    [string]$Output,
    [string]$Tool
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $Bin)    { $Bin    = Join-Path $root '..\..\bin' }
$Bin = (Resolve-Path $Bin).Path
if (-not $Output) { $Output = Join-Path $Bin 'sprites' }
if (-not $Tool)   { $Tool   = Join-Path $Bin 'SpritePackCli.exe' }

if (-not (Test-Path $Tool)) {
    throw "SpritePackCli.exe not found at $Tool - build the tool first."
}

# --- Tile themes ------------------------------------------------------
#
# Ordered: the first matching pattern claims a name. Move a pattern
# between sets and the next run reflects it - these tables are the whole
# of the decision, there is nowhere else to look.
#
# The mine (level 1) and the moonbase (level 2) both draw from
# textures\, so the split is by subject: brick is brick whichever level
# stands on it.

$rootThemes = [ordered]@{
    'brickwork'      = @('b1?', 'b2?', 'b3?')
    'mine-structure' = @('pol*', 'wall_*', 'stolb2', 'kruk')
    'moon-surface'   = @('moongrunt*', 'peshera*')
    'machinery'      = @('cooler*', 'ventelat', 'mash*', 'future*',
                         'provod*', 'lamp', 'hull51*')
    'facility'       = @('base?', 'triangle_base*', 'yashik*')
    'common'         = @('pustota', 'perehod', 'd8')
}

# textures\level1 - the mining complex. Four names here collide with
# textures\ (mash1..3 and pustota) and are DIFFERENT pictures, so they
# are routed to sets that hold no root tile of the same name.
$mineThemes = [ordered]@{
    'conveyor'      = @('lenta*')
    'mining-rig'    = @('digger_*', 'mash*')
    'railway'       = @('railway', 'vagon*', 'stolb', 'stolbend',
                        'stolbrail', 'platform*')
    'mine-walls'    = @('mrw*', 'tekmrw*', 'wall_?')
    'cargo'         = @('tov1_*', 'tov2_*', 'yashik')
    'mine-interior' = @('doorbnorm*', 'wallnorm*', 'winnorm*', 'par??',
                        'potolok', 'btw?', 'triangle', 'background2',
                        'doom1', 'pustota')
}

function Invoke-Pack {
    param(
        [Parameter(Mandatory)][string]$Folder,
        [Parameter(Mandatory)][string]$SetName,
        [string]$List
    )

    $target = Join-Path $Output "$SetName.mset"
    if (-not $PSCmdlet.ShouldProcess($target, 'pack')) { return }

    $arguments = @('pack', $Folder, $target, '--id', $SetName)
    if ($List -and (Test-Path $List)) { $arguments += @('--list', $List) }

    & $Tool @arguments
    if ($LASTEXITCODE -ne 0) { throw "Packing $SetName failed." }
}

# Tiles cannot simply be moved into themed folders: the game still reads
# them where they are and the level palettes still name those paths. So
# each theme is staged into a scratch folder, packed from there, and the
# scratch folder goes away. When the loose images retire, so does this
# dance.
function Invoke-PackThemes {
    param(
        [Parameter(Mandatory)][string]$Folder,
        [Parameter(Mandatory)][System.Object]$Themes,
        [Parameter(Mandatory)][string]$LeftoverSet
    )

    $unclaimed = [System.Collections.Generic.List[string]]::new()
    foreach ($file in Get-ChildItem $Folder -Filter *.png) {
        $unclaimed.Add($file.Name)
    }

    $stageRoot = Join-Path ([IO.Path]::GetTempPath()) 'mset-stage'

    foreach ($setName in @($Themes.Keys) + @($LeftoverSet)) {
        if ($setName -eq $LeftoverSet) {
            $taken = @($unclaimed)
            if ($taken.Count -gt 0) {
                Write-Warning ("No theme claimed {0} file(s) in {1}: {2}" -f `
                    $taken.Count, (Split-Path $Folder -Leaf),
                    ($taken -join ', '))
            }
        }
        else {
            $patterns = $Themes[$setName]
            $taken = @($unclaimed | Where-Object {
                $name = [IO.Path]::GetFileNameWithoutExtension($_)
                @($patterns | Where-Object { $name -like $_ }).Count -gt 0
            })
            foreach ($file in $taken) { [void]$unclaimed.Remove($file) }
        }
        if ($taken.Count -eq 0) { continue }

        Remove-Item $stageRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
        foreach ($file in $taken) {
            Copy-Item (Join-Path $Folder $file) $stageRoot
        }

        Invoke-Pack -Folder $stageRoot -SetName $setName
        Remove-Item $stageRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

New-Item -ItemType Directory -Force -Path $Output | Out-Null

# One set per monster. The .mns beside the folder carries frame order.
foreach ($folder in Get-ChildItem (Join-Path $Bin 'monsters') -Directory) {
    Invoke-Pack -Folder $folder.FullName -SetName $folder.Name `
                -List (Join-Path $folder.Parent.FullName "$($folder.Name).mns")
}

# The hero is the engine's default set; the weapons travel with him.
Invoke-Pack -Folder (Join-Path $Bin 'heroes') -SetName 'hero' `
            -List (Join-Path $Bin 'heroes\default.txt')
Invoke-Pack -Folder (Join-Path $Bin 'weapon') -SetName 'weapon' `
            -List (Join-Path $Bin 'weapon\default.txt')

Invoke-PackThemes -Folder (Join-Path $Bin 'textures') `
                  -Themes $rootThemes -LeftoverSet 'tiles-unsorted'
Invoke-PackThemes -Folder (Join-Path $Bin 'textures\level1') `
                  -Themes $mineThemes -LeftoverSet 'mine-unsorted'

# Screen backdrops: one set per level folder, named by the convention
# the engine follows - <assetsDir>-backdrops. Big opaque images, packed
# as they are.
foreach ($folder in Get-ChildItem (Join-Path $Bin 'levels') -Directory) {
    Invoke-Pack -Folder $folder.FullName -SetName "$($folder.Name)-backdrops"
}

Write-Host ''
Write-Host "Sets written to $Output" -ForegroundColor Green
Get-ChildItem $Output -Filter *.mset |
    Sort-Object Name |
    Format-Table Name, @{ Name = 'KB'; Expression = { [int]($_.Length / 1KB) } }
