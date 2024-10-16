# Monitoring app registration secrets
- This automation script is used to monitor app registration secrets, it will log all secrets which will expire within 30 days.
- The payload section can be filled in to match the parameters needed for your ticketing system, this payload can be forwarded to a webhook.
- Example in grafana oncall when payload is forwarded to the webhookUrl.
![secretAlert](https://github.com/user-attachments/assets/ecbec536-9b9b-4d69-afb2-bf4ec8083ca3)
