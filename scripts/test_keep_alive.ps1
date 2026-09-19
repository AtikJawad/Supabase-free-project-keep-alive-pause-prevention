# Test the Supabase keep-alive RPC endpoint.
#
# Usage:
# 1. Replace the two values below.
# 2. Run this script in PowerShell.
#
# Do NOT put private database passwords or service_role keys here.

$PROJECT_URL="https://YOUR_PROJECT_ID.supabase.co"
$SUPABASE_KEY="YOUR_PUBLISHABLE_OR_ANON_KEY"

$response = Invoke-RestMethod `
  -Uri "$PROJECT_URL/rest/v1/rpc/keep_alive" `
  -Method Post `
  -Headers @{
    apikey=$SUPABASE_KEY
    Authorization="Bearer $SUPABASE_KEY"
  } `
  -ContentType "application/json" `
  -Body "{}"

Write-Host "Supabase response: $response"

if ($response -eq 1) {
    Write-Host "Keep-alive test succeeded."
} else {
    Write-Host "Unexpected response. Check your Supabase URL, key, and function."
}
