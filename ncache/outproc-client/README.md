# NCache out-of-proc client cache

Runs an NCache out-of-proc client cache inside the cluster, plus a sample application pod that uses it.
The distributed cache itself runs on NCache servers, deployed from one of the platform folders.

| File | What it does |
|---|---|
| `ncache-client-outproc.yaml` | `ncache-client` Deployment (an NCache container registered as a client) and its Service, which keeps each pod talking to the client cache on its own node. |
| `app.yaml` | `myapp` sample Deployment (2 replicas) that reaches the client cache through `NCACHE_CLIENT_HOST=ncache-client`, and its headless Service. |
| `.env` | Values filled into both YAML files: `IMAGE_REPOSITORY`, `IMAGE_TAG`, `NCACHE_KEY`, `APP_IMAGE`. |

## Run

1. Set the values in `.env`. `APP_IMAGE` must already be on every node; `app.yaml` never pulls it.
2. Load the values and apply both files with them filled in:

   ```bash
   set -a; . ./.env; set +a
   ```

   ```bash
   envsubst < ncache-client-outproc.yaml | kubectl apply -f -
   ```

   ```bash
   envsubst < app.yaml | kubectl apply -f -
   ```

The `ncache-client` pod pulls its image with the `ncache-secret` docker-registry Secret. Create it if
your image is in a private registry.
