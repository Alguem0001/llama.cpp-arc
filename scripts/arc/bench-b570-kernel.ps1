# A/B: B570 optimized kernel vs normal (upstream-like)
# Usage: powershell -File scripts/arc/bench-b570-kernel.ps1 [-Model path] [-Reps 3]
param(
    [string]$Model = "C:\Users\geron\OneDrive\Desktop\AI\Bansai Llama.cpp\models\Ternary-Bonsai-1.7B-Q2_0_g64.gguf",
    [string]$Model27 = "C:\Users\geron\OneDrive\Desktop\AI\Bansai Llama.cpp\models\Bonsai-27B-Q1_0.gguf",
    [int]$Reps = 3,
    [switch]$Also27B
)

$ErrorActionPreference = "Continue"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$bench = Join-Path $Root "build-arc\bin\llama-bench.exe"
if (-not (Test-Path $bench)) { $bench = Join-Path $Root "build\bin\llama-bench.exe" }
if (-not (Test-Path $bench)) { throw "llama-bench.exe not found" }

$outDir = Join-Path $Root "benches\arc-b570"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

function Run-Bench($label, $envVal, $modelPath, $outFile) {
    Write-Host "`n======== $label ========" -ForegroundColor Cyan
    if ($null -eq $envVal) {
        Remove-Item Env:GGML_VK_B570_KERNEL -ErrorAction SilentlyContinue
    } else {
        $env:GGML_VK_B570_KERNEL = $envVal
    }
    Remove-Item Env:GGML_VK_ARC_FA_LEGACY -ErrorAction SilentlyContinue
    & $bench -m $modelPath -ngl 99 -fa on -p 512 -n 128 -r $Reps 2>&1 |
        Tee-Object -FilePath $outFile
}

# NORMAL first (upstream-like)
Run-Bench "NORMAL (GGML_VK_B570_KERNEL=0)" "0" $Model (Join-Path $outDir "kernel-normal-1.7b.txt")

# B570 optimized
Run-Bench "B570 OPT (GGML_VK_B570_KERNEL=1)" "1" $Model (Join-Path $outDir "kernel-opt-1.7b.txt")

if ($Also27B -and (Test-Path $Model27)) {
    Run-Bench "NORMAL 27B" "0" $Model27 (Join-Path $outDir "kernel-normal-27b.txt")
    Run-Bench "B570 OPT 27B" "1" $Model27 (Join-Path $outDir "kernel-opt-27b.txt")
}

Remove-Item Env:GGML_VK_B570_KERNEL -ErrorAction SilentlyContinue
Write-Host "`nDone. Results in $outDir" -ForegroundColor Green
