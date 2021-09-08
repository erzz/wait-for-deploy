#!/bin/bash
get_deployment_state() {
  STATE=$(curl -u ":$TOKEN" \
    "https://api.github.com/repos/$PROJECT/deployments/$DEPLOY_ID/statuses" \
    -H "Accept: application/vnd.github.v3+json" \
    | jq --raw-output '.[0].state')
  if [ -z "$STATE" ]; then
    echo "Couldn't get the deployment state. Are you sure you provided the correct project, id and credentials?"
    exit 1
  fi
}

while [ "$STATE" != "success" ] && [ "$STATE" != "failure" ] && [ "$STATE" != "error" ] && [ "$STATE" != "inactive" ]; do
  get_deployment_state
  if [ "$STATE" = "success" ] || [ "$STATE" = "inactive" ]; then
    echo "Deployment state is $STATE"
    echo "::set-output name=deploy-result::$STATE" && exit 0
  elif [ "$STATE" = "failure" ] || [ "$STATE" = "error" ]; then
    echo "Deployment state is $STATE"
    echo "::set-output name=deploy-result::$STATE" && exit "$EXIT_CODE"
  else
    echo "Deployment is currently in $STATE state, checking again in 10 seconds..."
    sleep 10
  fi
done