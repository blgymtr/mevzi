# MEVZİ sahne testleri — Windows / GPU (Forward+) çalıştırıcı
# Kullanım (PowerShell, proje kökünde):
#   .\tools\run_tests.ps1 -Godot "C:\Godot\godot.exe"
#   .\tools\run_tests.ps1 -Godot "C:\Godot\godot.exe" -Scenes crewtest,paratest -Timeout 300
# Her sahne ayrı süreçte çalışır; süre aşımında süreç öldürülür (takılma = TIMEOUT, sessiz bekleme yok).
# Ekran görüntüleri: shots\<sahne>\*.png · günlükler: shots\logs\<sahne>.log
# Çıkış kodu: tüm sahneler "RESULT fails=0" ise 0, değilse 1.
param(
	[Parameter(Mandatory = $true)][string]$Godot,
	[string[]]$Scenes = @("treetest", "dronetest", "woundtest", "ropetest", "crewtest", "paratest", "para2test", "fowtest", "tactest", "evadetest", "vfxtest", "rocktest", "largetest"),
	[int]$Timeout = 600,
	[switch]$NoImport
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$shots = Join-Path $root "shots"
$logs = Join-Path $shots "logs"
New-Item -ItemType Directory -Force -Path $logs | Out-Null
# Godot ekran görüntülerini içe aktarmasın (her çalıştırmada .import üretip taramayı yavaşlatıyordu)
New-Item -ItemType File -Force -Path (Join-Path $shots ".gdignore") | Out-Null

if (-not $NoImport) {
	Write-Host "== içe aktarma (yeni sınıflar/varlıklar için)"
	$p = Start-Process -FilePath $Godot -ArgumentList @("--headless", "--path", "`"$root`"", "--import") -NoNewWindow -PassThru `
		-RedirectStandardOutput (Join-Path $logs "_import.log") -RedirectStandardError (Join-Path $logs "_import.err")
	if (-not $p.WaitForExit(600 * 1000)) { $p.Kill(); Write-Host "içe aktarma süre aşımı" }
	$errs = Select-String -Path (Join-Path $logs "_import.*") -Pattern "SCRIPT ERROR|Parse Error|Compile Error" -ErrorAction SilentlyContinue
	if ($errs) { $errs | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }; Write-Host "Betik hataları var, testler durduruldu."; exit 1 }
}

$rows = @()
$bad = 0
foreach ($s in $Scenes) {
	$out = Join-Path $shots $s
	New-Item -ItemType Directory -Force -Path $out | Out-Null
	$log = Join-Path $logs "$s.log"
	$err = Join-Path $logs "$s.err"
	Write-Host "== $s"
	$t0 = Get-Date
	$p = Start-Process -FilePath $Godot -ArgumentList @("--path", "`"$root`"", "--", "--shot=`"$out`"", "--scene=$s") -NoNewWindow -PassThru `
		-RedirectStandardOutput $log -RedirectStandardError $err
	$outcome = ""
	if (-not $p.WaitForExit($Timeout * 1000)) {
		$p.Kill()
		$outcome = "TIMEOUT"
	}
	$sec = [math]::Round(((Get-Date) - $t0).TotalSeconds)
	$text = (Get-Content $log, $err -Raw -ErrorAction SilentlyContinue) -replace "`0", ""
	$res = [regex]::Match($text, "([A-Z0-9]+) RESULT fails=(\d+)")
	$fails = -1
	if ($res.Success) { $fails = [int]$res.Groups[2].Value }
	if ($outcome -eq "") {
		if ($text -match "SCRIPT ERROR") { $outcome = "SCRIPT ERROR" }
		elseif (-not $res.Success) { $outcome = "CRASH/NO RESULT" }
		elseif ($fails -eq 0) { $outcome = "OK" }
		else { $outcome = "FAIL" }
	}
	if ($outcome -ne "OK") { $bad++ }
	$rows += [pscustomobject]@{ Sahne = $s; Sonuc = $outcome; Fails = $fails; Sn = $sec }
	# test satırlarını göster (RESULT, ölçümler, hatalar)
	($text -split "`n") | Where-Object { $_ -match "RESULT|SCRIPT ERROR|TIMEOUT|^[A-Z]+ [a-z_]+=" } | Select-Object -First 25 | ForEach-Object { Write-Host "   $_" }
}
Write-Host ""
$rows | Format-Table -AutoSize
if ($bad -gt 0) { Write-Host "$bad sahne başarısız/takıldı" -ForegroundColor Red; exit 1 }
Write-Host "Tüm sahneler geçti" -ForegroundColor Green
exit 0
