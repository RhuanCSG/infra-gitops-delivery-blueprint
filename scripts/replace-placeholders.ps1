# Substitui os placeholders nos manifestos YAML com os valores do config.ps1
# Uso: .\scripts\replace-placeholders.ps1

$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir
$ConfigFile = Join-Path $ScriptDir "config.ps1"

if (-not (Test-Path $ConfigFile)) {
    Write-Error "Arquivo $ConfigFile nao encontrado.`nCopie scripts\config.ps1.example para scripts\config.ps1 e preencha seus valores."
    exit 1
}

. $ConfigFile

# Verificar variáveis obrigatórias
$requiredVars = @(
    "AWS_ACCOUNT_ID", "CLUSTER_NAME", "AWS_REGION", "KMS_KEY_ARN",
    "HARBOR_S3_BUCKET", "GITHUB_USERNAME", "HARBOR_ALB_HOSTNAME"
)

foreach ($var in $requiredVars) {
    if (-not (Get-Variable -Name $var -ErrorAction SilentlyContinue) -or
        [string]::IsNullOrEmpty((Get-Variable -Name $var).Value)) {
        Write-Error "Variavel $var nao definida em $ConfigFile"
        exit 1
    }
}

$placeholders = @{
    "<AWS_ACCOUNT_ID>"        = $AWS_ACCOUNT_ID
    "<CLUSTER_NAME>"          = $CLUSTER_NAME
    "<AWS_REGION>"            = $AWS_REGION
    "<KMS_KEY_ARN>"           = $KMS_KEY_ARN
    "<HARBOR_S3_BUCKET>"      = $HARBOR_S3_BUCKET
    "<GITHUB_USERNAME>"       = $GITHUB_USERNAME
    "<HARBOR_ALB_HOSTNAME>"   = $HARBOR_ALB_HOSTNAME
}

Write-Host "Substituindo placeholders em: $RepoRoot"

Get-ChildItem -Path $RepoRoot -Recurse -Include "*.yaml", "*.yml" |
    Where-Object { $_.FullName -notlike "*\scripts\*" } |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $changed = $false
        foreach ($entry in $placeholders.GetEnumerator()) {
            if ($content -like "*$($entry.Key)*") {
                $content = $content -replace [regex]::Escape($entry.Key), $entry.Value
                $changed = $true
            }
        }
        if ($changed) {
            Set-Content -Path $_.FullName -Value $content -NoNewline
            Write-Host "  OK $($_.FullName)"
        }
    }

Write-Host ""
Write-Host "Concluido. Verifique os arquivos antes de fazer push para o repositorio privado."
Write-Host "Para reverter: git checkout -- ."
