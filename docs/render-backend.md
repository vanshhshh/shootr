# Render Backend

This backend replaces the Firebase Functions-only path for payment verification,
admin bootstrap, and notification fanout.

## Required Render environment variables

- `FIREBASE_PROJECT_ID`: `shootr-app`
- `FIREBASE_SERVICE_ACCOUNT_JSON`: Firebase Admin SDK service account JSON
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`
- `BOOTSTRAP_ADMIN_EMAIL`: `vansh.sharma.cse@gmail.com`

## Deploy path

Render needs a GitHub, GitLab, or Bitbucket repository URL. After pushing this
project to a repo, create the service from `render.yaml` in the Dashboard or run:

```powershell
$env:RENDER_API_KEY="<your-render-api-key>"
$env:RENDER_REPO_URL="https://github.com/<owner>/<repo>"
$env:RAZORPAY_KEY_ID="<your-razorpay-key-id>"
$env:RAZORPAY_KEY_SECRET="<your-razorpay-key-secret>"
$env:RAZORPAY_WEBHOOK_SECRET="<your-razorpay-webhook-secret>"
$env:FIREBASE_SERVICE_ACCOUNT_JSON='<your-service-account-json>'
powershell -ExecutionPolicy Bypass -File scripts\deploy_render_backend.ps1
```

Then build the Flutter app with the service URL:

```powershell
flutter build apk --debug --dart-define=SHOOTR_BACKEND_URL=https://<service>.onrender.com
```

Set the Razorpay webhook URL to:

```text
https://<service>.onrender.com/api/razorpay-webhook
```
