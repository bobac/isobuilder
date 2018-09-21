$bucket = "YOURBUCKET"
$awsProfileName = "PowerShellProfile"
$isoFiles = Get-ChildItem iso\*.iso
Write-Host "Syncing new iso files to S3..."
foreach ($iso in $isoFiles) {
  Write-Host "ISO: $iso"
  $iso -match ".*\\(.*)$"
  $key = $matches[1]
  $keyPath = "iso/" + $key
  Write-Host "KeyPath: $keyPath"
  if ((Get-S3Object -BucketName $bucket -Key $keyPath -ProfileName $awsProfileName).Key) {
    Write-Host "ISO Exists on S3..."
  } else {
    Write-S3Object -BucketName $bucket -File $iso -Key $keyPath -CannedACLName public-read -ProfileName $awsProfileName
    $html1 = @'
       <html><head><meta http-equiv="refresh" content="0;url=
'@
    $html2 = @'
"></head><body></body></html>
'@
    $html = $html1 + "/$bucket/$keyPath" + $html2
    Out-File -InputObject $html -FilePath .\iso\Win2016EN.iso.latest
    Write-S3Object -BucketName $bucket -File .\iso\Win2016EN.iso.latest -Key iso\Win2016EN.iso.latest -ContentType:text/html -CannedACLName public-read -ProfileName $awsProfileName
    Out-File -InputObject $key -FilePath .\iso\latest.txt -Encoding ASCII -NoNewline
    Write-S3Object -BucketName $bucket -File .\iso\latest.txt -Key iso\latest.txt -ContentType:text/plain -CannedACLName public-read -ProfileName $awsProfileName
  }
}
