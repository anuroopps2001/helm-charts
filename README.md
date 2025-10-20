
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




# Helm Template functions

## 🧩 4️⃣ include Keyword – Reusing Templates
`include` lets you import a defined template (usually from _helpers.tpl) into another template.

`_helpers.tpl`
```
{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}
```

`Use in another file:`
```bash
metadata:
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
```

✅ | nindent 4 adds indentation for YAML alignment

## 🧩 5️⃣ with – Changing Context

`with` temporarily changes the . context to a specific object.
```bash
{{- with .Values.image }}
image: {{ .repository }}:{{ .tag }}
{{- end }}
```

Here, inside the with block, `.` refers to `.Values.image`.

## 🧩 6️⃣ range – Looping

`range` is used to iterate over lists or maps.
```bash
ports:
{{- range .Values.service.ports }}
  - containerPort: {{ . }}
{{- end }}
```

If `ports: [80, 8080]` in values.yaml, it renders:
```bash
ports:
  - containerPort: 80
  - containerPort: 8080
```

## 🧩 7️⃣ if Statements
Conditionally render blocks only if a value exists or is true.

```bash
{{- if .Values.image.pullSecrets }}
imagePullSecrets:
  {{- range .Values.image.pullSecrets }}
  - name: {{ . }}
  {{- end }}
{{- end }}
```
If no `pullSecrets` are defined, this block won’t render.

## 🧩 8️⃣ toYaml & nindent – Clean YAML Rendering
`toYaml` converts a dictionary or list into properly formatted YAML.

```bash
resources:
  {{- toYaml .Values.resources | nindent 2 }}
```

## 🧩 9️⃣ required – Mandatory Fields
Used to make sure a value is provided, otherwise Helm throws an error.

```bash
host: {{ required "ingress.host is required" .Values.ingress.host }}
```

If `.Values.ingress.host` is missing, Helm stops rendering.

## 🧩 🔟 printf, trunc, trimSuffix – String Manipulation

In `_helpers.tpl`
```bash
{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
```

## Values, Overrides, and Reusability in Helm
### 🧩 1️⃣ Understanding values.yaml

Each chart will be having `values.yaml` file

```bash
replicaCount: 2

image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
```

Usage in resource template files
```bash
{{ .Values.image.repository }}
{{ .Values.service.port }}
{{ .Values.replicaCount }}
```
### 🧠 2️⃣ Overriding Values

Helm allows you to override values.yaml at runtime using:

1. A separate values file (-f or --values)

2. The --set flag on the command line

```bash
helm install demo . -f values-prod.yaml

helm install demo . --set replicaCount=3 --set image.tag=stable
```

### 🧩 3️⃣ Conditional Resources
Sometimes you only want to create a resource if enabled in values.

`values.yaml`
```bash
persistence:
  enabled: true
```

`templates/pvc.yaml`

```bash
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "mychart.fullname" . }}-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
{{- end }}
```

✅ If `enabled: false`, Helm will not render that PVC manifest.

### 🧩 6️⃣ Default Values and Safe Fallbacks

Use the `default` function to prevent missing values from breaking templates.

```bash
imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
```

If the user doesn’t specify it in `values.yaml`, it will fall back to `IfNotPresent`.

### 🧩 8️⃣ Using toYaml and nindent for Nested Values

When rendering nested objects (like resources, tolerations, or affinity),
always use `toYaml` and `nindent` to maintain correct YAML structure.

```bash
resources:
{{ toYaml .Values.resources | nindent 2 }}
```

converts Into
```bash
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

We can use `environment specific values.yaml` files to deploy into different environments Quickly.

## Subcharts & Dependencies in Helm
### 🧩 1️⃣ What Are Subcharts
A subchart is a Helm chart that is used as a dependency inside another chart (the parent chart).

They are useful when:

* You want to include multiple related components (e.g. `app + database`)

* You want to reuse existing charts (e.g. Bitnami’s Redis, MySQL, etc.)

* You want modular and maintainable deployments

Example:

```bash
myapp/
├── Chart.yaml
├── values.yaml
├── charts/            # subcharts live here
│   └── redis/         # a subchart (dependency)
└── templates/
```

### 🧠 2️⃣ Declaring Dependencies
Dependencies are declared in the parent chart’s `Chart.yaml` under the `dependencies:` section.

Example:
```bash
apiVersion: v2
name: myapp
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: redis
    version: 17.x.x
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

📌 Notes:

 * name: — the chart name from the repo

* version: — the subchart version

* repository: — URL or local path

* condition: — optional key that enables/disables the subchart (redis.enabled in values.yaml)

### 🧩 3️⃣ Updating Dependencies
After defining dependencies in `Chart.yaml`, run:

```bash
helm dependency update
```

✅ This will:

* Download the subcharts listed in dependencies

* Store them inside the charts/ directory as .tgz packages

You can check them:
```bash
ls charts/
```

### 🧩 4️⃣ Configuring Subchart Values
Subchart configuration values are defined in the parent’s `values.yaml` under the subchart key.
Example:
```bash
redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: false
```
These values will override the subchart’s own defaults (`redis/values.yaml`).

To view what keys are available for configuration:
```bash
helm show values bitnami/redis
```

### 🧩 5️⃣ Enabling / Disabling a Subchart
You can use the `condition:` field (defined in Chart.yaml) to toggle deployment of a subchart.

Example:
```bash
# Chart.yaml
dependencies:
  - name: redis
    version: 17.x.x
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

In `values.yaml`:
```bash
redis:
  enabled: false
```

✅ When you run:
```bash
helm template demo .
```

Redis resources will not appear in the rendered output.

If you set `redis.enabled: true`, Helm will render and deploy all Redis manifests.

### 🧩 6️⃣ Inspecting Subchart Resources
After installation, you can verify subchart resources:

```bash
helm install demo . -n demo --create-namespace
kubectl get all -n demo -l app.kubernetes.io/instance=demo
```

Helm manages subcharts as part of the same release —
all subchart resources share the same `.Release.Name`.

### 🧩 7️⃣ Overriding Subchart Values
Option 1: using parent values.yaml

```bash
redis:
  master:
    persistence:
      size: 2Gi
```

Option 2: using CLI flag

```bash
helm install demo . -n demo --set redis.master.persistence.size=2Gi
```

Option 3: dedicated override file
```bash
helm install demo . -n demo -f values.yaml -f redis-overrides.yaml
```
### 🧩 8️⃣ Subchart Value Scope
* Subchart values are namespaced under their chart name.
Example: `redis.master.persistence.size`

* Subcharts cannot access parent values, unless explicitly defined under `global:`.

### 🧩 9️⃣ Using Global Values
You can define shared values in the `global:` section of `values.yaml`.
These are visible to both parent and subcharts.

Example:
```bash
global:
  imageRegistry: myregistry.io

redis:
  image:
    registry: {{ .Values.global.imageRegistry }}
```

### 🧩 🔟 Verifying Dependency Tree
To list dependencies declared for a chart:
```bash
helm dependency list
```

To verify if they are downloaded properly:
```bash
helm dependency update
ls charts/
```

To inspect subchart details:
```bash
helm show chart charts/redis-*.tgz
```

### 🧩 11️⃣ Real Example: myapp with Redis Subchart

`Chart.yaml`
```bash
apiVersion: v2
name: myapp
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: redis
    version: 17.9.2
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

`values.yaml`
```bash
redis:
  enabled: true
  auth:
    enabled: false
```

Commands:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency update
helm install demo . -n demo --create-namespace
```

Result:

* Helm installs both your myapp templates and the Redis resources from Bitnami.

### 🧩 12️⃣ Disabling the Subchart
If you set in `values.yaml`:

```bash
redis:
  enabled: false
```

and run:
```bash
helm template demo .
```

✅ Only your custom templates will render — no Redis resources.

### 🧩 13️⃣ Subchart Lifecycle
* Subchart upgrades automatically when the parent chart is upgraded.

* Each subchart’s templates are rendered during the parent’s `helm install` / `upgrade`.

* Subchart hooks (pre/post-install) also execute as part of the same Helm release.

