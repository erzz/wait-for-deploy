# wait-for-deploy

Wait for any deployment job's status even from other workflows and projects.

## Purpose

Simple action that basically can be used to wait for a deployment to end. That deployment can be in another workflow or even another project as long as you have credentials to see it.

The specific case I built this for was to have a workflow that is triggered with `on: deployment` which, due to Github's lazyness with implementing a real deployment model so far, doesn't actually have the ability to follow the state of that deployment in another workflow without a bunch of API calls. 

By getting the deployment ID from the Github event that triggers the workflow - we can then use this action in such a detached workflow to wait for the deployment to complete and return the status.

## Inputs

| Input                  | Description                                                      | Required | Default Value   |
| ---------------------- | ---------------------------------------------------------------- | -------- | --------------- |
| `project`              | The owner/repo of the project in which the deployment runs       | true     | `""`            |
| `token`                | A secret holding a PAT or similar to access the project          | true     | `""`            |
| `deploy-id`            | The ID of the deployment you wish to follow                      | true     | `""`            |
| `exit-code-on-failure` | The exit code for this action to use if the deployment is failed | false    | `0`             |

## Outputs

| Output                 | Description                   | Example    |
| ---------------------- | ----------------------------- | ---------- |
| `deploy-result`        | The status of the deployment  | `success`  |
## Example Usage

```yaml
name: Deployment Metrics
on: deployment

jobs:
  deployment-start:
    name: Deployment Start
    runs-on: ubuntu-latest
    outputs:
      deployment-id: ${{ steps.info.outputs.id }}
      result: ${{ steps.wait.outputs.deploy-result }}
    steps:
      # Create outputs for things we are interested in
      - name: Get Deployment information
        id: info
        run: |
          echo "::set-output name=deployment-id::$(jq .event.deployment.id $GITHUB_EVENT_PATH)"

      # Ping the deployment started metric
      - name: Notify Deployment Start
        run: echo "Deployment ${{ steps.info.outputs.deployment-id }} has started."

      # Wait for deployment to complete
      - name: Wait for Deployment End 
        uses: erzz/wait-for-deploy@v1
        id: wait
        with:
          github-token: ${{ secrets.SOME_TOKEN }}
          project: someone-else/project-name
          deploy-id: ${{ steps.info.outputs.deployment-id }}
          exit-code-on-failure: 0

  deployment-end:
      name: Deployment End
      needs: deployment-start
      runs-on: ubuntu-latest
      steps:
        - run: echo "The deployment ${{ needs.deployment-start.outputs.deployment-id }} completed with the status ${{ needs.deployment-start.outputs.result }}"
```

