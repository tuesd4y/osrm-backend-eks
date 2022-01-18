# osrm-backend for AWS Elastic Kubernetes Service

This docker image can be used in two different modes: The `CREATE` mode downloads a `.osm.pbf` file, builds a routing graphs and uploads it to a specified S3 bucket, and the `LOAD` mode downloads a graph from a specified S3 bucket and starts an OSRM backend server on port 5000.

## Usage

### Downloading source files and building a graph

```bash
docker run -d -p 5000:5000 \
-e OSRM_PBF_URL='http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf' \
-e OSRM_DATA_LABEL='berlin-new' \
-e OSRM_S3_BUCKET='s3://triply-routing-data' \
-e OSRM_AWS_ACCESS_KEY_ID='YOUR_ACCESS_KEY' \
-e OSRM_AWS_SECRET_ACCESS_KEY='YOUR/SECRET' \
-e OSRM_WEBHOOK_URL='https://example.com/post' \
--name osrm-backend tuesd4y/osrm-backend-eks:latest
```

In the create mode, if `OSRM_WEBHOOK_URL` is set, the following body is posted to the given URL.

```json
{
  "label":"$OSRM_DATA_LABEL", 
  "mode":"$OSRM_GRAPH_PROFILE",
  "source":"$OSRM_PBF_URL",
  "target":"$OSRM_S3_BUCKET/$OSRM_DATA_LABEL"
}
```

If `OSRM_EXIT_AFTER_UPLOAD` is set to anything not-empty, an OSRM instance is started on port 5000 after the graph is built and uploaded. Otherwise, the container exists after the graph is built and uploaded to the S3 bucket.

### Downloading a pre-built graph and starting routing

```bash
docker run -d -p 5000:5000 \
-e OSRM_DATA_LABEL='berlin-new' \
-e OSRM_MODE='LOAD' \
-e OSRM_S3_BUCKET='s3://triply-routing-data' \
-e OSRM_AWS_ACCESS_KEY_ID='YOUR_ACCESS_KEY' \
-e OSRM_AWS_SECRET_ACCESS_KEY='YOUR/SECRET' \
--name osrm-backend-load tuesd4y/osrm-backend-eks:latest
```

Check that the router is running by looking at the responses here of a routing request:

`curl http://localhost:5000/route/v1/driving/13.388860,52.517037;13.385983,52.496891?steps=true`

## Configuration Options

### OSRM configuration

| env variable | default value | explanation |
| --- | --- | --- |
| `OSRM_MODE`| `CREATE` | Defines if a new graph should be created (`CREATE`) or an existing one should be downloaded (`LOAD`) |
| `OSRM_DATA_PATH` | `/osrm-data` | Path to store the downloaded osm files and built graph |
| `OSRM_DATA_LABEL` | `data` | Name under which the built graph should be stored or loaded from in the S3 bucket |
| `OSRM_GRAPH_PROFILE` | `car` | Profile to use for creating the routing graph (see [here](https://github.com/Project-OSRM/osrm-backend/tree/master/profiles) for available profiles)|
| `OSRM_PBF_URL` | <http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf> | URL from where to load the graph to build (only used in `CREATE` mode) |
| `OSRM_MAX_TABLE_SIZE` | `8000` | `max-table-size` parameter to be passed to the `osrm-routed` script |
| `OSRM_WEBHOOK_URL` | - | webhook that's called after data has been uploaded to S3 (only used in `CREATE` mode) |
| `OSRM_EXIT_AFTER_UPLOAD` | - | If the docker container should exit after the graph is built (only used in `CREATE` mode), if set to empty, the container serves an OSRM instance on port 5000 |

### AWS-specific configuration

| env variable | default value | explanation |
| --- | --- | --- |
| `OSRM_S3_BUCKET` | - | S3 bucket where the built graph should be or is stored |
| `OSRM_AWS_REGION` | `eu-central-1` | AWS region the bucket is located in |
| `OSRM_AWS_ACCESS_KEY_ID` | - | Access key id to be used for accessing the S3 bucket |
| `OSRM_AWS_SECRET_ACCESS_KEY` | - | Secret access key to be used for accessing the S3 bucket |

## Changelog

### v1.1

- Add webhook (enabled by setting `OSRM_WEBHOOK_URL`) to `CREATE` mode
- Allow configuring if the OSRM instance should run after data has been uploaded in `CREATE` by setting `OSRM_EXIT_AFTER_UPLOAD`

### v1

- Initial release

## License

Released under the MIT License, please see [License](./LICENSE) for more details.

This repository is heavily inspired by the previous work of Peter Evans in his [osrm-backend-k8s](https://github.com/peter-evans/osrm-backend-k8s) repository.
