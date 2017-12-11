# Build Production Image
export DEPLOY_TAG="${CIRCLE_BUILD_NUM}_${CIRCLE_SHA1:0:7}"

# Deploy via DeployManager
./deploymanager "rake docker:build_deploy"
