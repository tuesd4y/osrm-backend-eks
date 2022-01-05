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
--name osrm-backend tuesd4y/osrm-backend-eks:latest
```

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
| `OSRM_GRAPH_PROFILE` | `car` | Transport mode to use for creating the routing graph |
| `OSRM_PBF_URL` | <http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf> | URL from where to load the graph to build (only used in `CREATE` mode) |
| `OSRM_MAX_TABLE_SIZE` | `8000` | `max-table-size` parameter to be passed to the `osrm-routed` script |

### AWS-specific configuration

| env variable | default value | explanation |
| --- | --- | --- |
| `OSRM_S3_BUCKET` | - | S3 bucket where the built graph should be or is stored |
| `OSRM_AWS_REGION` | `eu-central-1` | AWS region the bucket is located in |
| `OSRM_AWS_ACCESS_KEY_ID` | - | Access key id to be used for accessing the S3 bucket |
| `OSRM_AWS_SECRET_ACCESS_KEY` | - | Secret access key to be used for accessing the S3 bucket |

## License

Released under the MIT License, please see [License](./LICENSE) for more details.

This repository is heavily inspired by the previous work of Peter Evans in his [osrm-backend-k8s](https://github.com/peter-evans/osrm-backend-k8s) repository.