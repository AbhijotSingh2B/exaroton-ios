# Exaroton API: Minecraft Server Data Reference

When extending the Exaroton iOS App, you may need to map new data points from the Exaroton API. This document serves as a quick reference for the data exposed by the Exaroton REST API and WebSocket streams.

## 1. The Server Object
When you query `GET /v1/servers/` or `GET /v1/servers/{id}/`, the API returns a JSON "Server object" with the following primary fields:

```json
{
  "id": "abc123def456",
  "name": "My Minecraft Server",
  "address": "example.exaroton.me",
  "motd": "Welcome to the server!",
  "status": 0,
  "host": "node1.exaroton.com",
  "port": 25565,
  "players": {
    "max": 20,
    "count": 5,
    "list": ["Notch", "Jeb"]
  },
  "software": {
    "id": "paper",
    "name": "PaperMC",
    "version": "1.20.4"
  },
  "shared": false
}
```

### Status Codes
The `status` field is an integer representing the lifecycle state of the server:
- `0`: Offline
- `1`: Online
- `2`: Starting
- `3`: Stopping
- `4`: Restarting
- `5`: Saving
- `6`: Loading
- `7`: Crashed
- `8`: Pending

## 2. Account & Billing Endpoints
The API allows you to fetch metadata about the user's Exaroton account and their credit balances.

- **Account Data:** `GET /v1/account/`
  Returns the user's `name`, `email`, `verified` status, and current `credits`.
- **Credit Pools:** `GET /v1/billing/pools/`
  Returns an array of `CreditPool` objects, which include `id`, `name`, `credits`, `owner`, and `share` flags.

## 3. Server Management Endpoints
Beyond the base server object, the Exaroton API exposes dedicated endpoints to fetch deeper configuration and perform actions:

- **Actions:** 
  - `POST /v1/servers/{id}/start`
  - `POST /v1/servers/{id}/stop`
  - `POST /v1/servers/{id}/restart`
  - `POST /v1/servers/{id}/command` (Body: `{"command": "say Hello"}`)
  
- **Configuration & Hardware:**
  - `GET /v1/servers/{id}/options/ram/` (Returns allocated RAM between 2-16 GB)
  - `POST /v1/servers/{id}/options/ram/` (Updates allocated RAM; requires server restart to take effect)
  - `GET /v1/servers/{id}/options` (Returns `server.properties` key-value pairs)
  
- **Players & Files:**
  - `GET /v1/servers/{id}/playerlists` (Lists available files like `whitelist.json`, `ops.json`, `banned-players.json`)
  - `PUT /v1/servers/{id}/playerlists/{list}/` (Add a player, pass `{"entries": ["username"]}` in body)
  - `DELETE /v1/servers/{id}/playerlists/{list}/` (Remove a player, pass `{"entries": ["username"]}` in body)
  - `GET /v1/servers/{id}/files/info/{path}` (Returns file size, type, and children for a directory)
  - `GET /v1/servers/{id}/files/data/{path}` (Returns raw file contents)
  - `PUT /v1/servers/{id}/files/data/{path}` (Upload/overwrite a file, pass raw string in body)
  - `DELETE /v1/servers/{id}/files/data/{path}` (Delete a file)

## 4. Real-Time Data (WebSocket API)
Exaroton does not support webhooks. All real-time telemetry must be fetched by opening a WebSocket connection to `wss://api.exaroton.com/v1/servers/{id}/websocket` and sending authentication via the `authorization` query parameter.

The app can subscribe to multiple "streams" by sending a JSON payload (e.g., `{"stream": "tick", "type": "start"}`). The API will respond with JSON messages containing:
- **`status`**: Broadcasts the integer status code the moment the server state changes.
- **`console`**: Pushes new terminal lines (`stdout`) in real-time.
- **`stats`**: Pushes RAM memory usage percentage and absolute byte usage. (Note: CPU load is **not** provided by the exaroton API).
- **`heap`**: Pushes raw JVM heap byte usage. (Only available for Java-based servers).
- **`tick`**: Pushes the server's Average Tick Time (MSPT) which can be used to calculate TPS (20 TPS = 50ms). Note: TPS information is only available for Minecraft Java Edition servers running version 1.16 or higher.

## Implementation Note
Always ensure that data types (like nested `software` objects or `players` structs) are properly mirrored in `Sources/ExarotonApp/Networking/Models/` using `Codable` structs before trying to parse new API endpoints.
