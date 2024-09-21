#!/bin/bash

# Run docker-compose sudo command
# Create directories
mkdir -p /data
mkdir -p /data/mssql_data
mkdir -p /data/mssql_backup
mkdir -p /data/mssql_doc

# Build image
docker compose up --build