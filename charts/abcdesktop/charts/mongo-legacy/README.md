# MongoDB Subchart for ABCDesktop

This chart deploys MongoDB for ABCDesktop.

## Installation

### As part of ABCDesktop
```bash
helm install abcdesktop ./charts/abcdesktop --set mongo.enabled=true
```

### Standalone
```bash
helm install mongo ./charts/abcdesktop/charts/mongo
```

## Configuration

See `values.yaml` for all available configuration options.

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable MongoDB | `true` |
| `image.repository` | MongoDB image | `ghcr.io/abcdesktopio/mongo` |
| `image.tag` | Image tag | `safemain` |
| `replicaCount` | Number of replicas | `1` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |