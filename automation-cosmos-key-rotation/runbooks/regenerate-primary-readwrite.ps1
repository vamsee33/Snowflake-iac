$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

$cosmosResourceId = '${cosmos_account_id}'
$cosmosAccountName = '${cosmos_account_name}'
$cosmosResourceGroupName = '${cosmos_resource_group_name}'
$keyVaultName = '${key_vault_name}'
$secretName = '${secret_name}'
$keyKind = '${key_kind}'
$keyValue = $null
$secureValue = $null

try {
    $azCliVersionText = & az version --query '"azure-cli"' --output tsv 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($azCliVersionText)) {
        throw 'Azure CLI is unavailable.'
    }
    if ([version]$azCliVersionText -lt [version]'2.64.0') {
        throw 'Azure CLI runtime version is unsupported.'
    }

    & az login --identity --output none 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Managed Identity sign-in failed.'
    }

    & az cosmosdb keys regenerate --name $cosmosAccountName --resource-group $cosmosResourceGroupName --key-kind $keyKind --output none 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Cosmos DB key regeneration failed.'
    }

    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity -ErrorAction Stop | Out-Null

    $keys = Get-AzCosmosDBAccountKey -ResourceId $cosmosResourceId -Type Keys -ErrorAction Stop
    $keyValue = [string]$keys.PrimaryMasterKey

    if ([string]::IsNullOrWhiteSpace($keyValue)) {
        throw 'The requested key was not returned.'
    }

    $secureValue = ConvertTo-SecureString -String $keyValue -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secureValue -ErrorAction Stop | Out-Null
    Write-Output 'Cosmos DB key rotation completed and the new key was stored in Key Vault.'
}
catch {
    Write-Error 'Cosmos DB key rotation failed. The error details are suppressed to prevent sensitive data exposure.' -ErrorAction Continue
    throw 'Key rotation failed.'
}
finally {
    $keyValue = $null
    $secureValue = $null
    $keys = $null
}