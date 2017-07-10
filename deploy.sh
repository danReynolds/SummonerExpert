# Load Secrets into Environment File
bundle exec rake secrets:decrypt

# Generate new production tag based on Circle build
export DEPLOY_TAG="${CIRCLE_BUILD_NUM}_${CIRCLE_SHA1:0:7}"

# Build Production Image
docker build -f Dockerfile.prod -t danreynolds/summonerexpert:$DEPLOY_TAG .

# Push Image to Docker Hub
docker login -u $DOCKER_USER -p $DOCKER_PASS

# Create nginx_default network required to run production config
docker network create nginx_default

# Deploy to Production
docker-compose -f docker-compose.yml -f docker-compose.production.yml run app rspec
