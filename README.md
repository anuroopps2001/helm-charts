
# Helm repos

## Add external repo(s) & update index
```bash
# add repo (example: Bitnami)
helm repo add bitnami https://charts.bitnami.com/bitnami

# list configured repos
helm repo list

# refresh local index from remote repos
helm repo update
```

## List charts inside a repo / inspect chart details
```bash
# list all charts in a repo (search)
helm search repo bitnami

# show available versions of a chart
helm search repo bitnami/redis --versions

# show default values.yaml for a chart (very useful to know which keys to override)
helm show values bitnami/redis

# show README / docs for a chart
helm show readme bitnami/redis

# show complete chart metadata and files (chart + values + readme)
helm show all bitnami/redis
```

## Preview (render) a chart locally (safe — doesn't touch cluster)
```bash
# render chart from repo to stdout (no install)
helm template demo bitnami/redis

# render parent chart in current dir using specific values files (base + env)
helm template myapp . -f values.yaml -f values-prod.yaml --debug
```

## Install a chart (real) — safe steps
```bash
# Install chart from remote repo into namespace `demo` (creates namespace)
helm install demo bitnami/redis -n demo --create-namespace

# Install from local chart directory (custom chart)
helm install myapp . -n dev --create-namespace -f values.yaml -f values-dev.yaml

# perform a dry-run + debug to preview an install (no cluster changes)
helm install demo bitnami/redis -n demo --dry-run --debug
```

## Inspecting a release (what Helm actually applied)
```bash
# list releases in a namespace
helm list -n demo

# show release status (summary)
helm status demo -n demo

# get all release info (manifests, hooks, notes)
helm get all demo -n demo

# get only the rendered manifest that Helm applied
helm get manifest demo -n demo

# get the values used for this release (merged)
helm get values demo -n demo

# get the notes file (notes.txt from chart)
helm get notes demo -n demo
```

## Upgrade / dry-run / atomic / rollback (release lifecycle)
```bash
# preview an upgrade (dry run + debug)
helm upgrade demo bitnami/redis -n demo --dry-run --debug -f new-values.yaml

# do a real upgrade; use --atomic to auto-rollback on failure
helm upgrade demo bitnami/redis -n demo -f new-values.yaml --atomic

# list revision history of a release
helm history demo -n demo

# rollback to a specific revision (e.g. revision 1)
helm rollback demo 1 -n demo

# uninstall (delete) a release
helm uninstall demo -n demo
```

## Useful validation & debug commands (always run these while editing)
```bash
# lint chart for template/YAML issues
helm lint .

# render templates to check indentation & final YAML
helm template myapp . -f values.yaml -f values-dev.yaml --debug

# show merged values (quick debug trick: temporarily create a template that prints `toYaml .Values`)
# or use helm get values for an installed release
helm get values <release> -n <ns>
```

## Work with dependencies / subcharts
```bash
# declare dependencies in Chart.yaml, then download them locally
helm dependency update

# list downloaded vendored charts (charts/)
ls -la charts/

# inspect a chart inside the repo without downloading
helm show values bitnami/redis

# if you vendor (charts/*.tgz), inspect the package
tar -tzf charts/redis-*.tgz | sed -n '1,60p'
```

#### If a subchart should be conditional, add condition: redis.enabled in Chart.yaml and set redis.enabled: false in parent values to skip it.

## Create & develop your own chart (from scratch)
```bash
# scaffold a chart
helm create myapp

# edit files (Chart.yaml, values.yaml, templates/*). After edits, always:
helm lint myapp
helm template myapp -f myapp/values.yaml -f myapp/values-dev.yaml

# package a chart for release
helm package myapp
# output -> myapp-0.1.0.tgz

# create a repo index (for publishing to a static site)
helm repo index . --url https://<your-host>/charts
# then upload the .tgz and index.yaml to that host (GitHub Pages / S3 / ChartMuseum)
```

## Multi-env pattern: deploy same chart to dev/prod with different values
```bash
# preview dev
helm template myapp . -f values.yaml -f values-dev.yaml

# install dev
helm upgrade --install myapp-dev . -n dev --create-namespace -f values.yaml -f values-dev.yaml

# install prod
helm upgrade --install myapp-prod . -n prod --create-namespace -f values.yaml -f values-prod.yaml

# override single value on CLI (highest precedence)
helm upgrade --install myapp-prod . -n prod -f values.yaml -f values-prod.yaml --set image.tag=1.2.3 --atomic
```
