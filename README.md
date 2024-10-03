# Scripts

Scripts shared between argocd gs repositories.

## `get-limits`

Helper to get the limits, useful to used before applying a new limit on the namespace.

## `get-requests`

Helper to used tp get the request of the resource to be able to update them.

## `login`

Helper to login the the cluster.

## `new-project`

Helper to create a new GeoMapFish project based on files present on `/apps/example`.

## `parse-logs`

Helper to parse the JSON logs of a container.

## `pods-errors`

Helper to get all the pod on errors.

## `psql`

Helper to connect to the database, cal also be used to run `pg_dump` and `pg_restore` (run all of them locally with the database credentials).

## `template-gen`

Helper used to generate the Kubernetes object from the Helm template with the right list of values.

## `argocd-diff`

Used in the CI to print the diff with group aon application.

## `argocd-sync`

Not used currently but made to do an ArgoCD sync, with a blacklist of applications.

## `create-pullrequest`

Used by CI to create a pull request.

## `snyk-images`

Used by the CI to checks and monitor all the images with Snyk

## `update-image-hash`

Used by the CI to update the image hash in the values files.
