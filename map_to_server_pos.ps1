# Ask user to enter the location of the xml file
$xmlPath = Read-Host "Enter the location of the xml file"

# Load xml file
$xml = [xml](Get-Content $xmlPath)

# Find the <spawn-points> tree and its values in the xml file, and based on the example provided, rewrite the <spawn-points> just like the json example
$spawnPoints = @()
foreach ($sp in $xml.selectNodes("//spawn-points/spawn-point")) {
    $spawnPoint = @{
        "mode" = ($sp.type.ToUpper() -replace "DOM", "CP");
        "position" = @{
            "x" = [double]$sp.position.SelectSingleNode("x").InnerText;
            "y" = [double]$sp.position.SelectSingleNode("y").InnerText;
            "z" = [double]$sp.position.SelectSingleNode("z").InnerText
        };
        "rotation" = @{
            "x" = 0;
            "y" = 0;
            "z" = [double]$sp.rotation.SelectSingleNode("z").InnerText * 100
        }
    }
    if ($sp.type -match "DOM") {
        $spawnPoint.Add("team", $sp.team.ToUpper())
    }
    $spawnPoints += $spawnPoint
}

# Find the <dom-keypoints> tree and its values in the xml file, and based on the example provided, rewrite the <dom-keypoints> just like the json example
$points = @()
foreach ($dp in $xml.selectNodes("//dom-keypoints/dom-keypoint")) {
    $point = @{
        "id" = $dp.name.ToUpper();
        "distance" = [int]$dp.distance;
        "free" = [bool]($dp.free -eq "true");
        "position" = @{
            "x" = [double]$dp.position.SelectSingleNode("x").InnerText;
            "y" = [double]$dp.position.SelectSingleNode("y").InnerText;
            "z" = [double]$dp.position.SelectSingleNode("z").InnerText
        }
    }
    $points += $point
}

# Find the <ctf-flags> tree and its values in the xml file, and based on the example provided, rewrite the <ctf-flags> just like the json example
$flags = @{
    "RED" = @{
        "position" = @{
            "x" = [double]$xml.selectSingleNode("//ctf-flags/flag-red/x").InnerText;
            "y" = [double]$xml.selectSingleNode("//ctf-flags/flag-red/y").InnerText;
            "z" = [double]$xml.selectSingleNode("//ctf-flags/flag-red/z").InnerText
        }
    };
    "BLUE" = @{
        "position" = @{
            "x" = [double]$xml.selectSingleNode("//ctf-flags/flag-blue/x").InnerText;
            "y" = [double]$xml.selectSingleNode("//ctf-flags/flag-blue/y").InnerText;
            "z" = [double]$xml.selectSingleNode("//ctf-flags/flag-blue/z").InnerText
        }
    }
}

# Find the <bonus-region> tree and its values in the xml file, and based on the example provided, rewrite the <bonus-region> just like the json example
$bonuses = @()
foreach ($bonus in $xml.selectNodes("//bonus-region")) {
    $types = @()
    foreach ($type in $bonus."bonus-type") {
        switch ($type) {
            "crystal_100" { $types += "gold" }
            "damageup" { $types += "double_damage" }
            "armorup" { $types += "double_armor" }
            "medkit" { $types += "health" }
            default { $types += $type }
        }
    }

    $modes = @()
    foreach ($mode in $bonus."game-mode") {
        $modes += ($mode -replace "DOM", "CP").ToUpper()
    }

    $bonusObject = @{
        "name" = $bonus.name;
        "free" = [bool]($bonus.free -eq "true");
        "types" = $types;
        "modes" = $modes;
        "parachute" = [bool]($bonus.parachute -eq "true");
        "position" = @{
            "min" = @{
                "x" = [double]$bonus.min.SelectSingleNode("x").InnerText;
                "y" = [double]$bonus.min.SelectSingleNode("y").InnerText;
                "z" = [double]$bonus.min.SelectSingleNode("z").InnerText;
            };
            "max" = @{
                "x" = [double]$bonus.max.SelectSingleNode("x").InnerText;
                "y" = [double]$bonus.max.SelectSingleNode("y").InnerText;
                "z" = [double]$bonus.max.SelectSingleNode("z").InnerText;
            }
        };
        "rotation" = @{
            "x" = 0;
            "y" = 0;
            "z" = [double]$bonus.rotation.z * 180 / [math]::pi
        }
    }
    $bonuses += $bonusObject
}

# Create json object
$json = @{
    "spawnPoints" = $spawnPoints;
    "points" = $points;
    "flags" = $flags;
    "bonuses" = $bonuses
} | ConvertTo-Json -Depth 4

# Print the rewritten json
Write-Output $json

# Keep the PowerShell console open
Write-Host "Press Enter to exit."
while (-not ([console]::KeyAvailable -and ([console]::ReadKey($true)).Key -eq "Enter")) {}