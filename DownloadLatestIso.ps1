Param(
  [String]$workingDirectory
)

if ($workingDirectory) {
  New-Item -ItemType Directory -Force -Path $workingDirectory
  cd $workingDirectory
}

Write-Host "Creating ISO folder..."
New-Item -ItemType Directory -Force -Path .\iso

$iso = Invoke-WebRequest -Uri https://YOURURL/latest.txt
$downurl = "https://YOURURL/" + $iso.content

$isoPath = ".\iso\" + $iso
Write-Host "Checking if iso $isoPath exist..."
if (Test-Path $isoPath -PathType Leaf){
  Write-Host "...iso exists."
} else {
  Write-Host "...iso does not exist."
  Start-BitsTransfer -Source $downurl -Destination iso\
  New-Item -Path .\iso\latest.iso -ItemType SymbolicLink -Value $isoPath
}
Write-Host "Done."
