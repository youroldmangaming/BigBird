docker stop storage-node

# Build the container
docker compose build no-cache

# Start the service
docker compose up -d

# View logs for debugging
docker compose logs -f storage-node≈y

