#!/bin/bash

if [ "$OSRM_MODE" != "CREATE" ] && [ "$OSRM_MODE" != "LOAD" ]; then
  # Default to CREATE
  OSRM_MODE="CREATE"
fi

# General and OSRM variables
OSRM_DATA_PATH=${OSRM_DATA_PATH:="/osrm-data"}
OSRM_DATA_LABEL=${OSRM_DATA_LABEL:="data"}
OSRM_GRAPH_PROFILE=${OSRM_GRAPH_PROFILE:="car"}
OSRM_PBF_URL=${OSRM_PBF_URL:="http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf"}
OSRM_MAX_TABLE_SIZE=${OSRM_MAX_TABLE_SIZE:="8000"}
OSRM_WEBHOOK_URL=${OSRM_WEBHOOK_URL:=""}
OSRM_EXIT_AFTER_UPLOAD=${OSRM_EXIT_AFTER_UPLOAD:=""}

# AWS S3 Storage variables
OSRM_S3_BUCKET=${OSRM_S3_BUCKET:=""}
OSRM_AWS_REGION=${OSRM_AWS_REGION:="eu-central-1"}
OSRM_AWS_ACCESS_KEY_ID=${OSRM_AWS_ACCESS_KEY_ID:=""}
OSRM_AWS_SECRET_ACCESS_KEY=${OSRM_AWS_SECRET_ACCESS_KEY:=""}

_sig() {
  kill -TERM $child 2>/dev/null
}
trap _sig SIGKILL SIGTERM SIGHUP SIGINT EXIT

if [ "$OSRM_MODE" == "CREATE" ]; then

  # Retrieve the PBF file
  curl -L $OSRM_PBF_URL --create-dirs -o $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osm.pbf

  # Build the graph
  osrm-extract $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osm.pbf -p /osrm-profiles/$OSRM_GRAPH_PROFILE.lua
  osrm-contract $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osrm

  # delete now unused osm pbf file
  rm $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osm.pbf

  if [ ! -z "$OSRM_S3_BUCKET" ] && [ ! -z "$OSRM_AWS_REGION" ] && [ ! -z "$OSRM_AWS_ACCESS_KEY_ID" ] && [ ! -z "$OSRM_AWS_SECRET_ACCESS_KEY" ]; then

    # configure keys for AWS access
    aws configure set aws_access_key_id "$OSRM_AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$OSRM_AWS_SECRET_ACCESS_KEY"
    aws configure set default.region "$OSRM_AWS_REGION"

    # Copy the graph to storage
    aws s3 cp $OSRM_DATA_PATH $OSRM_S3_BUCKET/$OSRM_DATA_LABEL --recursive

    # Call webhook URL (if not empty) with information that the files were uploaded successfully
    if [ ! -z "$OSRM_WEBHOOK_URL" ]; then
      echo "Calling webhook at $OSRM_WEBHOOK_URL"
      curl -d "{
        \"label\":\"$OSRM_DATA_LABEL\", 
        \"mode\":\"$OSRM_GRAPH_PROFILE\",
        \"source\":\"$OSRM_PBF_URL\",
        \"target\":\"$OSRM_S3_BUCKET/$OSRM_DATA_LABEL\"
        }" -H "Content-Type: application/json" -X POST "$OSRM_WEBHOOK_URL"
    fi

    if [ ! -z "$OSRM_EXIT_AFTER_UPLOAD" ]; then
      echo "OSRM_EXIT_AFTER_UPLOAD is set, exiting now"
      exit 0
    fi
  fi

else

  if [ ! -z "$OSRM_S3_BUCKET" ] && [ ! -z "$OSRM_AWS_REGION" ] && [ ! -z "$OSRM_AWS_ACCESS_KEY_ID" ] && [ ! -z "$OSRM_AWS_SECRET_ACCESS_KEY" ]; then

    # configure keys for AWS access
    aws configure set aws_access_key_id "$OSRM_AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$OSRM_AWS_SECRET_ACCESS_KEY"
    aws configure set default.region "$OSRM_AWS_REGION"

    # Copy the graph from storage
    aws s3 cp $OSRM_S3_BUCKET/$OSRM_DATA_LABEL $OSRM_DATA_PATH --recursive
  fi

fi

# Start serving requests
osrm-routed $OSRM_DATA_PATH/$OSRM_DATA_LABEL.osrm --max-table-size $OSRM_MAX_TABLE_SIZE &
child=$!
wait "$child"
