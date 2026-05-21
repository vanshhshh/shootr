param(
  [string]$RepoUrl = $env:RENDER_REPO_URL,
  [string]$OwnerId = $env:RENDER_OWNER_ID,
  [string]$Name = "shootr-backend",
  [string]$Branch = "main",
  [string]$Plan = "free",
  [string]$Region = "singapore"
)

$ErrorActionPreference = "Stop"

if (-not $env:RENDER_API_KEY) {
  throw "Set RENDER_API_KEY before running this script."
}

if (-not $RepoUrl) {
  throw "Set RENDER_REPO_URL or pass -RepoUrl. Render needs a GitHub/GitLab/Bitbucket repo URL."
}

if (-not $OwnerId) {
  $headers = @{
    Authorization = "Bearer $env:RENDER_API_KEY"
    Accept        = "application/json"
  }
  $services = Invoke-RestMethod -Method Get -Uri "https://api.render.com/v1/services?limit=1" -Headers $headers
  if (-not $services -or -not $services[0].service.ownerId) {
    throw "Could not infer Render owner ID. Set RENDER_OWNER_ID from your Render workspace settings."
  }
  $OwnerId = $services[0].service.ownerId
}

$requiredEnv = @(
  "RAZORPAY_KEY_ID",
  "RAZORPAY_KEY_SECRET",
  "RAZORPAY_WEBHOOK_SECRET",
  "FIREBASE_SERVICE_ACCOUNT_JSON"
)

foreach ($name in $requiredEnv) {
  if (-not [Environment]::GetEnvironmentVariable($name)) {
    throw "Set $name before running this script."
  }
}

$envVars = @(
  @{ key = "NODE_ENV"; value = "production" },
  @{ key = "FIREBASE_PROJECT_ID"; value = "shootr-app" },
  @{ key = "BOOTSTRAP_ADMIN_EMAIL"; value = "vansh.sharma.cse@gmail.com" },
  @{ key = "RAZORPAY_KEY_ID"; value = $env:RAZORPAY_KEY_ID },
  @{ key = "RAZORPAY_KEY_SECRET"; value = $env:RAZORPAY_KEY_SECRET },
  @{ key = "RAZORPAY_WEBHOOK_SECRET"; value = $env:RAZORPAY_WEBHOOK_SECRET },
  @{ key = "FIREBASE_SERVICE_ACCOUNT_JSON"; value = $env:FIREBASE_SERVICE_ACCOUNT_JSON }
)

$body = @{
  type           = "web_service"
  name           = $Name
  ownerId        = $OwnerId
  repo           = $RepoUrl
  branch         = $Branch
  rootDir        = "backend"
  autoDeploy     = "yes"
  envVars        = $envVars
  serviceDetails = @{
    runtime            = "node"
    plan               = $Plan
    region             = $Region
    healthCheckPath    = "/health"
    numInstances       = 1
    envSpecificDetails = @{
      buildCommand = "npm ci"
      startCommand = "npm start"
    }
  }
} | ConvertTo-Json -Depth 20

$createHeaders = @{
  Authorization  = "Bearer $env:RENDER_API_KEY"
  Accept         = "application/json"
  "Content-Type" = "application/json"
}

Invoke-RestMethod -Method Post -Uri "https://api.render.com/v1/services" -Headers $createHeaders -Body $body |
  ConvertTo-Json -Depth 20
