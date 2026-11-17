$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

$cosmosResourceId = '${cosmos_account_id}'
$cosmosAccountName = '${cosmos_account_name}'
$cosmosResourceGroupName = '${cosmos_resource_group_name}'
$storageAccountName = '${storage_account_name}'
$storageResourceGroupName = '${storage_resource_group_name}'
$keyVaultName = '${key_vault_name}'
$cosmosReadWriteSecret = '${cosmos_readwrite_secret}'
$cosmosReadOnlySecret = '${cosmos_readonly_secret}'
$storageSecret = '${storage_secret}'
$cosmosReadWriteKey = $null
$cosmosReadOnlyKey = $null
$storageKey = $null
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

    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity -ErrorAction Stop | Out-Null

    & az cosmosdb keys regenerate --name $cosmosAccountName --resource-group $cosmosResourceGroupName --key-kind primary --output none 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Cosmos DB primary key regeneration failed.'
    }
    $cosmosKeys = Get-AzCosmosDBAccountKey -ResourceId $cosmosResourceId -Type Keys -ErrorAction Stop
    $cosmosReadWriteKey = [string]$cosmosKeys.PrimaryMasterKey
    $cosmosKeys = $null
    if ([string]::IsNullOrWhiteSpace($cosmosReadWriteKey)) {
        throw 'The Cosmos DB primary read-write key was not returned.'
    }
    $secureValue = ConvertTo-SecureString -String $cosmosReadWriteKey -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $cosmosReadWriteSecret -SecretValue $secureValue -ErrorAction Stop | Out-Null
    $cosmosReadWriteKey = $null
    $secureValue = $null

    & az cosmosdb keys regenerate --name $cosmosAccountName --resource-group $cosmosResourceGroupName --key-kind primaryReadonly --output none 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Cosmos DB primary read-only key regeneration failed.'
    }
    $cosmosKeys = Get-AzCosmosDBAccountKey -ResourceId $cosmosResourceId -Type ReadOnlyKeys -ErrorAction Stop
    $cosmosReadOnlyKey = [string]$cosmosKeys.PrimaryReadonlyMasterKey
    $cosmosKeys = $null
    if ([string]::IsNullOrWhiteSpace($cosmosReadOnlyKey)) {
        throw 'The Cosmos DB primary read-only key was not returned.'
    }
    $secureValue = ConvertTo-SecureString -String $cosmosReadOnlyKey -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $cosmosReadOnlySecret -SecretValue $secureValue -ErrorAction Stop | Out-Null
    $cosmosReadOnlyKey = $null
    $secureValue = $null

    & az storage account keys renew --account-name $storageAccountName --resource-group $storageResourceGroupName --key primary --output none --only-show-errors 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Storage Account primary key regeneration failed.'
    }
    $storageKey = & az storage account keys list --account-name $storageAccountName --resource-group $storageResourceGroupName --query "[?keyName=='key1'].value | [0]" --output tsv --only-show-errors 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Storage Account key retrieval failed.'
    }
    $storageKey = [string]$storageKey
    if ([string]::IsNullOrWhiteSpace($storageKey)) {
        throw 'The Storage Account primary key was not returned.'
    }
    $secureValue = ConvertTo-SecureString -String $storageKey -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $storageSecret -SecretValue $secureValue -ErrorAction Stop | Out-Null
    Write-Output 'Primary Cosmos DB and Storage Account key rotation completed; all new keys were stored in Key Vault.'
}
catch {
    Write-Error 'Primary key rotation failed. Details are suppressed to prevent sensitive data exposure.' -ErrorAction Continue
    throw 'Primary key rotation failed.'
}
finally {
    $cosmosReadWriteKey = $null
    $cosmosReadOnlyKey = $null
    $storageKey = $null
    $secureValue = $null
    $cosmosKeys = $null
}