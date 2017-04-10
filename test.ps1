$ErrorActionPreference = "Stop"

$pivotalNetworkApiToken = ""

$authenticationResponse = Invoke-WebRequest `
    -UseBasicParsing `
    -Uri "https://network.pivotal.io/api/v2/authentication" `
    -ContentType "application/json" `
    -Headers @{ 
        "Authorization"="Token $pivotalNetworkApiToken"; 
        "Accept"="application/json"}

function Get-PivotalNetworkCanonicalUrl([string]$relativePath){
    return "https://network.pivotal.io/api/v2/" + $relativePath.TrimStart('/')
}

function Get-PivotalNetworkObjectResponse([string]$relativePath){
    $uri = Get-PivotalNetworkCanonicalUrl -relativePath $relativePath
    $response = Invoke-WebRequest `
        -UseBasicParsing `
        -Uri $uri `
        -ContentType "application/json" `
        -Headers @{ 
            "Authorization"="Token $pivotalNetworkApiToken"; 
            "Accept"="application/json"}
    return $response
}

function Set-PivotalNetworkObject([string]$relativePath, $body){
    $uri = Get-PivotalNetworkCanonicalUrl -relativePath $relativePath
    if($body -eq $null){
        $response = Invoke-WebRequest `
            -UseBasicParsing `
            -Uri $uri `
            -ContentType "application/json" `
            -Method Post `
            -Headers @{ 
                "Authorization"="Token $pivotalNetworkApiToken"; 
                "Accept"="application/json";
                "Content-Length"="0"}
        return $response
    }
    $response = Invoke-WebRequest `
        -UseBasicParsing `
        -Uri $uri `
        -ContentType "application/json" `
        -Method Post `
        -Headers @{ 
            "Authorization"="Token $pivotalNetworkApiToken"; 
            "Accept"="application/json";
            "Content-Length"="0"}
    return $response
}

function Invoke-PivotalNetworkDownloadFile([string]$relativePath, [string] $filePath){    
    $uri = Get-PivotalNetworkCanonicalUrl -relativePath $relativePath
    
    Invoke-WebRequest `
        -Uri $uri `
        -ContentType "application/json" `
        -Headers @{ 
            "Authorization"="Token $pivotalNetworkApiToken"; 
            "Accept"="application/json";
            "Content-Length"="0"} `
        -OutFile $filePath
}

function Get-PivotalNetworkProducts(){
    $response = Get-PivotalNetworkObjectResponse -relativePath "/products"
    if($response.StatusCode -ne 200){        
        throw "Unable to get products"
    }
    $responseContentJson = $response.Content
    $response = ConvertFrom-Json $responseContentJson
    return $response.products
}

<#
    Gets all pivotal network product by product id
#>
function Get-PivotalNetworkProductById([int]$productId){
    # $products = Get-PivotalNetworkProducts
    $relativePath = "/products/$productId"
    $response = Get-PivotalNetworkObjectResponse -relativePath $relativePath
    if($response.StatusCode -ne 200){
        throw "Unable to get product $productId"
    }
    $product = ConvertFrom-Json $response.Content
    return $product
}

<#
    Gets all pivotal network releases by product id
#>
function Get-PivotalNetworkReleasesByProductId([int] $productId){
    $response = Get-PivotalNetworkObjectResponse -relativePath "/products/$productId/releases"
    if($response.StatusCode -ne 200){        
        throw "Unable to get releases by product id $productId"
    }
    $responseContentJson = $response.Content
    $response = ConvertFrom-Json $responseContentJson
    return $response.releases
}

<#
    Gets A Pivotal Release by Product Id and Release Id
 #>
function Get-PivotalNetworkReleaseByProductIdAndReleaseId([int] $productId, [int]$releaseId){    
    $response = Get-PivotalNetworkObjectResponse -relativePath "/products/$productId/releases/$releaseId"
    if($response.StatusCode -ne 200){
        throw "Unable to get release"
    }    
    $responseContentJson = $response.Content
    $response = ConvertFrom-Json $responseContentJson
    return $response
}

<#
    Gets a Pivotal Network Release  by Product Id and Release Version Number
#>
function Get-PivotalNetworkReleaseByProductIdAndReleaseVersionNumber([int]$productId, [string]$releaseVersionNumber){
    
    # get the product by id 
    $releases = Get-PivotalNetworkReleasesByProductId $productId

    foreach($release in $releases){
        if($release.version -eq $releaseVersionNumber){
            return Get-PivotalnetworkReleaseByProductIdAndReleaseId -productId $productId -releaseId $release.id
        }
    }

    throw "Release Version Not Found for productid: $productId release version:$releaseVersionNumber"
}

<#
#>
function Set-PivotalNetworkEulaAcceptedByProductIdAndReleaseVersionNumber([int]$productId, [string]$releaseVersionNumber){
    $release = Get-PivotalNetworkReleaseByProductIdAndReleaseVersionNumber -productId $productId -releaseVersionNumber $releaseVersionNumber
    $relativePath = "/products/$productId/releases/$($release.id)/eula_acceptance"
    $response = Set-PivotalNetworkObject -relativePath $relativePath
    if($response.StatusCode -ne 200){
        throw "Unable to set acceptance for product $productId version $releaseVersionNumber"
    }
}

<#
    Downloads the file 
#>
function Invoke-PivotalNetworkDownloadFileByProductIdAndReleaseIdAndProductFileId([int]$productId, [int]$releaseId, [int]$productFileId, [string] $filePath){
    $relativePath = "/products/$productId/releases/$releaseId/product_files/$productFileId/download"
    Invoke-PivotalNetworkDownloadFile -relativePath $relativePath -filePath $filePath
}

$pivotalCloudFoundryDesiredState = ConvertFrom-Json "
    [
        {
            'name': 'Pivotal Cloud Foundry Elastic Runtime',
            'id': 60,
            'version':'1.8.10',
            'file':''
        },
        {
            'name': 'MySQL for PCF',
            'id': 41,
            'version':'1.8.6',
            'file':'p-mysql-1.8.6.pivotal'
        },
        {
            'name': 'Pivotal Cloud Foundry Operations Manager',
            'id': 78,
            'version':'1.8.10',
            'file': 'pcf-vsphere-1.8.10.ova'
        }
    ]
" 
<#
Get-PivotalNetworkProducts
Get-PivotalNetworkReleasesByProductId -productId 154
Get-PivotalNetworkReleaseByProductIdAndReleaseId -productId 78 -releaseId 4854
Get-PivotalNetworkReleaseByProductIdAndReleaseVersionNumber -productId 78 -releaseVersionNumber "1.10.3"
Set-PivotalNetworkEulaAcceptedByProductIdAndReleaseVersionNumber -productid 78 -releaseVersionNumber "1.10.3"
Invoke-PivotalNetworkDownloadFileByProductIdAndReleaseIdAndProductFileId -productId 78 -releaseId 4854 -productFileId 17664 -filePath c:\temp\temp.bin
#>

Get-PivotalNetworkProductById -productId 60
Get-PivotalNetworkReleaseByProductIdAndReleaseVersionNumber -productId 60 -releaseVersionNumber "1.3.5.0"