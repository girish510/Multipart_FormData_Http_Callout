# 🔄 Multipart Form-Data HTTP Callout via Flow (Invocable Apex)
This project provides a reusable Apex class that allows Salesforce Flows to send multipart/form-data HTTP callouts — ideal for file uploads and form submissions to external APIs.

# 📦 Features
- Upload files to external services from Flow

- Supports multipart/form-data format (e.g. file + description)

- Accepts Base64-encoded file content

- Returns status code and response body

- Fully configurable through Flow Action using Invocable Apex

# ⚙️ How It Works
The AddBeforePhoto_Flow class exposes an Invocable method that can be used in Flow. It constructs a multipart/form-data body, sends an HTTP POST request, and returns the response.

# 📌 Notes
- This callout must run in an asynchronous context or with Callout-enabled Flow.

- File must be encoded as Base64 string before calling.

- Apex class must have access to the Remote Site Setting or Named Credential configured for the target URL.

# 🔐 Remote Site Setting
- Make sure to add the external API domain to Remote Site Settings in Setup:

- Setup → Security → Remote Site Settings → New
  URL: https://example.com
  Label: Your API Endpoint
