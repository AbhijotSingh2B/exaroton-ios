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

## 2. Server Management Endpoints
Beyond the base server object, the Exaroton API exposes dedicated endpoints to fetch deeper configuration and perform actions:

- **Actions:** 
  - `POST /v1/servers/{id}/start`
  - `POST /v1/servers/{id}/stop`
  - `POST /v1/servers/{id}/restart`
  - `POST /v1/servers/{id}/command` (Body: `{"command": "say Hello"}`)
  
- **Configuration & Hardware:**
  - `GET /v1/servers/{id}/ram` (Returns allocated RAM in GB)
  - `POST /v1/servers/{id}/ram` (Updates allocated RAM)
  - `GET /v1/servers/{id}/options` (Returns `server.properties` key-value pairs)
  
- **Players & Files:**
  - `GET /v1/servers/{id}/playerlists` (Lists available files like `whitelist.json`, `ops.json`, `banned-players.json`)
  - `GET /v1/servers/{id}/files/info/{path}` (Returns file size, type, and children for a directory)
  - `GET /v1/servers/{id}/files/data/{path}` (Returns raw file contents)

## 3. Real-Time Data (WebSocket API)
Exaroton does not support webhooks. All real-time telemetry must be fetched by opening a WebSocket connection to `wss://api.exaroton.com/v1/servers/{id}/websocket` and sending authentication via the `authorization` query parameter.

The app can subscribe to multiple "streams" by sending a JSON payload (`{"stream": "console", "type": "start"}`). The API will respond with JSON messages containing:
- **`status`**: Broadcasts the integer status code the moment the server state changes.
- **`console`**: Pushes new terminal lines (`stdout`) in real-time.
- **`stats`**: Pushes RAM usage percentages and CPU load (useful for the `AnimatedGauge` component).
- **`heap`**: Pushes raw JVM heap byte usage.
- **`tick`**: Pushes the server's Average Tick Time (MSPT) which can be used to calculate TPS (20 TPS = 50ms).

## Implementation Note
Always ensure that data types (like nested `software` objects or `players` structs) are properly mirrored in `Sources/ExarotonApp/Networking/Models/` using `Codable` structs before trying to parse new API endpoints.
