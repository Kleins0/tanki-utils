$dirPath = Read-Host "Enter directory path"
$cacheDir = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "cache"

# check if cache directory exists and prompt to delete files
if (Test-Path $cacheDir) {
  if ((Get-ChildItem $cacheDir).Count -gt 0) {
    $deleteCache = Read-Host "The custom cache directory is not empty. Do you want to delete all files? [y/n]"
    if ($deleteCache.ToLower() -eq "y") {
      Remove-Item $cacheDir/* -Recurse -Force | Out-Null
    }
  }
} else {
  New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
}

# copy files to cache directory and rename
$items = Get-ChildItem -Path $dirPath
foreach ($item in $items) {
  $sourcePath = $item.FullName
  $encodedName = $item.Name
  $decodedName = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedName))

  # replace invalid characters in filename
  $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
  foreach ($char in $invalidChars) {
    $decodedName = $decodedName -replace [regex]::Escape($char), "_"
  }

  $destinationPath = Join-Path $cacheDir $decodedName
  if (Test-Path $destinationPath) {
    $i = 1
    $newPath = $destinationPath -replace "(?<=\.)[^.]+$", "$i$&"
    while (Test-Path $newPath) {
      $i++
      $newPath = $destinationPath -replace "(?<=\.)[^.]+$", "$i$&"
    }	
    $destinationPath = $newPath
  }
  
  # replace `.tnk` file extensions to `.jpg`
  Get-ChildItem -Path $cacheDir -Filter *.tnk | ForEach-Object {
    $oldName = $_.FullName
    $newName = $_.Name.Replace('.tnk', '.jpg')
    $newPath = Join-Path -Path $cacheDir -ChildPath $newName
    Rename-Item -Path $oldName -NewName $newName -ErrorAction SilentlyContinue
}

  try {
    Copy-Item -Path $sourcePath -Destination $destinationPath
    Rename-Item -Path $destinationPath -NewName ($decodedName) -ErrorAction Stop
  } catch {
    $logPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "renaming_log.txt"
    Add-Content $logPath $_.Exception.Message
  }
}

Write-Host "Renaming complete. Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')