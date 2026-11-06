# Gera o RateioFatura.exe a partir do código em src\.
# Uso: clique com o botão direito > "Executar com o PowerShell", ou rode:
#   powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$src  = Join-Path $root 'src'
$out  = Join-Path $root 'build'
New-Item -ItemType Directory -Force $out | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding($false)
$page   = [IO.File]::ReadAllText((Join-Path $src 'rateio-fatura.html'), $utf8)
$pdf    = [IO.File]::ReadAllText((Join-Path $src 'lib\pdf.min.js'), $utf8)
$worker = [IO.File]::ReadAllText((Join-Path $src 'lib\pdf.worker.min.js'), $utf8)
$supa   = [IO.File]::ReadAllText((Join-Path $src 'lib\supabase.min.js'), $utf8)

# Página completa, com o leitor de PDF e a biblioteca do banco (Supabase) embutidos.
# O Supabase entra no <head> porque o login usa ele assim que a página abre.
$html = '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' +
        "`n<script>" + $supa + "</script></head><body>" +
        $page + "`n<script>" + $pdf + "</script>`n<script>" + $worker + "</script></body></html>"
$app = Join-Path $out 'app.html'
[IO.File]::WriteAllText($app, $html, $utf8)
Copy-Item $app (Join-Path $root 'Rateio da Fatura.html') -Force

$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
& $csc /nologo /target:winexe /optimize+ /codepage:65001 `
  "/out:$(Join-Path $root 'RateioFatura.exe')" "/resource:$app,app.html" `
  /reference:System.Windows.Forms.dll (Join-Path $src 'Program.cs')
if ($LASTEXITCODE -ne 0) { throw 'A compilação falhou.' }
Write-Host 'Pronto: RateioFatura.exe'
