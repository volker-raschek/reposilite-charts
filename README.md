# Reposilite

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/volker-raschek)](https://artifacthub.io/packages/search?repo=volker-raschek)

> [!NOTE]
> This is not the official helm chart of Reposilite. If you are looking for the official helm chart, checkout the GitHub
> project [reposilite-playground](https://github.com/reposilite-playground/reposilite-helm).

This helm chart enables the deployment of [Reposilite](https://github.com/dzikoysk/reposilite), a lightweight and
easy-to-use repository management software dedicated for the Maven-based artifacts in the JVM ecosystem.

The helm chart supports the individual configuration of additional containers/initContainers, mounting of volumes,
defining additional environment variables and much more.

Chapter [configuration and installation](#helm-configuration-and-installation) describes the basics how to configure helm
and use it to deploy the exporter. It also contains further configuration examples.

Furthermore, this helm chart contains unit tests to detect regressions and stabilize the deployment. Additionally, this
helm chart is tested for deployment scenarios with **ArgoCD**.

## Helm: configuration and installation

1. A helm chart repository must be configured, to pull the helm charts from.
2. All available [parameters](#parameters) are documented in detail below. The parameters can be defined via the helm
   `--set` flag or directly as part of a `values.yaml` file. The following example defines the `reposilite` repository
   and use the `--set` flag for a basic deployment.

```bash
helm repo add volker.raschek https://charts.cryptic.systems/volker.raschek
helm repo update
helm install reposilite volker.raschek/reposilite
```

Instead of passing all parameters via the *set* flag, it is also possible to define them as part of the `values.yaml`.
The following command downloads the `values.yaml` for a specific version of this chart. Please keep in mind, that the
version of the chart must be in sync with the `values.yaml`. Newer *minor* versions can have new features. New *major*
versions can break something!

```bash
CHART_VERSION=0.3.0
helm show values volker.raschek/reposilite --version "${CHART_VERSION}" > values.yaml
```

A complete list of available helm chart versions can be displayed via the following command:

```bash
helm search repo reposilite --versions
```

The helm chart also contains a persistent volume claim definition. It persistent volume claim is not enabled by default.
Use the `--set` argument to persist your data.

```bash
CHART_VERSION=0.3.0
helm install --version "${CHART_VERSION}" reposilite volker.raschek/reposilite \
  persistentVolumeClaim.enabled=true
```

### Examples

The following examples serve as individual configurations and as inspiration for how deployment problems can be solved.

#### TLS encryption

The example describe how to deploy Reposilite with TLS encryption. If Reposilite is deployed behind reverse proxy, for
example an ingress nginx controller, please instruct the ingress to establish an TLS encrypted connection to avoid
connection problems.

> [!WARNING]
> The secret `reposilite-tls` containing the TLS certificate is already present. The keys `ca.crt`, `tls.key` and
> `tls.crt` must be renamed matching the file extension `.pem`. Otherwise throws the used TLS library of Reposilite and
> error.

```bash
CHART_VERSION=0.3.0
helm install --version "${CHART_VERSION}" reposilite volker.raschek/reposilite \
  --set 'deployment.reposilite.env[1].name=REPOSILITE_LOCAL_SSLENABLED' \
  --set 'deployment.reposilite.env[1].value="true"' \
  --set 'deployment.reposilite.env[2].name=REPOSILITE_LOCAL_SSLPORT' \
  --set 'deployment.reposilite.env[2].value=8443' \
  --set 'deployment.reposilite.env[3].name=REPOSILITE_LOCAL_KEYPATH' \
  --set 'deployment.reposilite.env[3].value="/etc/reposilite/tls/cert.pem /etc/reposilite/tls/priv-key.pem"' \
  --set 'deployment.reposilite.volumeMounts[0].name=tls' \
  --set 'deployment.reposilite.volumeMounts[0].mountPath=/etc/reposilite/tls' \
  --set 'deployment.reposilite.volumeMounts[0].readOnly=true' \
  --set 'deployment.volumes[0].name=tls' \
  --set 'deployment.volumes[0].items[0].key=ca.crt' \
  --set 'deployment.volumes[0].items[0].path=ca.pem' \
  --set 'deployment.volumes[0].items[1].key=tls.crt' \
  --set 'deployment.volumes[0].items[1].path=cert.pem' \
  --set 'deployment.volumes[0].items[2].key=tls.key' \
  --set 'deployment.volumes[0].items[2].path=priv-key.pem' \
  --set 'deployment.volumes[0].secret.secretName=reposilite-tls' \
  --set 'service.port=8443'
```

#### TLS certificate rotation

If Reposilite uses TLS certificates that are mounted as a secret in the container file system like the example
[above](#tls-encryption), Reposlite will not automatically apply them when the TLS certificates are rotated. Such a
rotation can be for example triggered, when the [cert-manager](https://cert-manager.io/) issues new TLS certificates
before expiring.

Until Reposilite does not support rotating TLS certificate a workaround can be applied. For example stakater's
[reloader](https://github.com/stakater/Reloader) controller can be used to trigger a rolling update. The following
annotation must be added to instruct the reloader controller to trigger a rolling update, when the mounted configMaps
and secrets have been changed.

```yaml
deployment:
  annotations:
    reloader.stakater.com/auto: "true"
```

Instead of triggering a rolling update for configMap and secret resources, this action can also be defined for
individual items. For example, when the secret named `reposilite-tls` is mounted and the reloader controller should only
listen for changes of this secret:

```yaml
deployment:
  annotations:
    secret.reloader.stakater.com/reload: "reposilite-tls"
```

#### Network policies

Network policies can only take effect, when the used CNI plugin support network policies. The chart supports no custom
network policy implementation of CNI plugins. It's support only the official API resource of `networking.k8s.io/v1`.

The example below is an excerpt of the `values.yaml` file. The network policy contains ingress rules to allow incoming
traffic from an ingress controller. Additionally two egress rules are defined. The first one to allow the application
outgoing access to the internal running DNS server `core-dns`. The second rule to be able to access the Apache Maven
Central repository via HTTPS.

> [!IMPORTANT]
> Please keep in mind, that the namespace and pod selector labels can be different from environment to environment. For
> this reason, there is are not default network policy rules defined.

```yaml
networkPolicies:
  enabled: true
  annotations: {}
  labels: {}
  policyTypes:
  - Egress
  - Ingress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - port: 53
      protocol: TCP
    - port: 53
      protocol: UDP
  - ports:
    - port: 443
      protocol: TCP

  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
      podSelector:
        matchLabels:
          app.kubernetes.io/name: ingress-nginx
    ports:
    - port: http
      protocol: TCP
```

### Prometheus

Reposilite is not able to expose metrics by default. Reposilite requires an additional plugin to expose the metrics via
`/metrics`. The plugin will be downloaded from Apache Maven Central, when the plugin is enabled directly or the
Prometheus feature has been enabled. The plugin is a simple JAR file, which will be stored in `/app/data/plugins`.

Furthermore, Reposilite will not expose the metrics without protection. For this reason must be defined basic auth
credentials. By default generate the helm chart a random username and password for basic auth. For debugging propose can
be set the credentials manually.

The following example enable Prometheus metrics with custom basic auth credentials:

```bash
CHART_VERSION=0.3.0
helm install --version "${CHART_VERSION}" reposilite volker.raschek/reposilite \
  --set 'prometheus.metrics.enabled=true' \
  --set 'prometheus.metrics.basicAuthUsername=my-username' \
  --set 'prometheus.metrics.basicAuthUsername=my-password'
```

## Parameters

### Global

| Name               | Description                               | Value |
| ------------------ | ----------------------------------------- | ----- |
| `nameOverride`     | Individual release name suffix.           | `""`  |
| `fullnameOverride` | Override the complete release name logic. | `""`  |

### Config

| Name                                | Description                                                                                                                                    | Value                                                                                                                                                     |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `config.plugins.prometheus.enabled` | Download the Prometheus plugin via an additional init container. The Prometheus plugin will automatically enabled, when Prometheus is enabled. | `false`                                                                                                                                                   |
| `config.plugins.prometheus.url`     | URL to download the plugin.                                                                                                                    | `https://maven.reposilite.com/releases/com/reposilite/plugin/prometheus-plugin/{{ .Chart.AppVersion }}/prometheus-plugin-{{ .Chart.AppVersion }}-all.jar` |

### Deployment

| Name                                               | Description                                                                                                | Value                                       |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| `deployment.annotations`                           | Additional deployment annotations.                                                                         | `{}`                                        |
| `deployment.labels`                                | Additional deployment labels.                                                                              | `{}`                                        |
| `deployment.additionalContainers`                  | List of additional containers.                                                                             | `[]`                                        |
| `deployment.affinity`                              | Affinity for the Reposilite deployment.                                                                    | `{}`                                        |
| `deployment.initContainers`                        | List of additional init containers.                                                                        | `[]`                                        |
| `deployment.dnsConfig`                             | dnsConfig of the Reposilite deployment.                                                                    | `{}`                                        |
| `deployment.dnsPolicy`                             | dnsPolicy of the Reposilite deployment.                                                                    | `""`                                        |
| `deployment.hostname`                              | Individual hostname of the pod.                                                                            | `""`                                        |
| `deployment.subdomain`                             | Individual domain of the pod.                                                                              | `""`                                        |
| `deployment.hostNetwork`                           | Use the kernel network namespace of the host system.                                                       | `false`                                     |
| `deployment.imagePullSecrets`                      | Secret to use for pulling the image.                                                                       | `[]`                                        |
| `deployment.reposilite.args`                       | Arguments passed to the Reposilite container.                                                              | `[]`                                        |
| `deployment.reposilite.command`                    | Command passed to the Reposilite container.                                                                | `[]`                                        |
| `deployment.reposilite.env`                        | List of environment variables for the Reposilite container.                                                |                                             |
| `deployment.reposilite.envFrom`                    | List of environment variables mounted from configMaps or secrets for the Reposilite container.             | `[]`                                        |
| `deployment.reposilite.image.registry`             | Image registry, eg. `docker.io`.                                                                           | `docker.io`                                 |
| `deployment.reposilite.image.repository`           | Image repository, eg. `library/busybox`.                                                                   | `dzikoysk/reposilite`                       |
| `deployment.reposilite.image.tag`                  | Custom image tag, eg. `0.1.0`. Defaults to `appVersion`.                                                   | `""`                                        |
| `deployment.reposilite.image.pullPolicy`           | Image pull policy.                                                                                         | `IfNotPresent`                              |
| `deployment.reposilite.resources`                  | CPU and memory resources of the pod.                                                                       | `{}`                                        |
| `deployment.reposilite.securityContext`            | Security context of the container of the deployment.                                                       | `{}`                                        |
| `deployment.reposilite.volumeMounts`               | Additional volume mounts.                                                                                  | `[]`                                        |
| `deployment.nodeSelector`                          | NodeSelector of the Reposilite deployment.                                                                 | `{}`                                        |
| `deployment.pluginContainer.args`                  | Arguments passed to the plugin container.                                                                  | `["--location","--fail","--max-time","60"]` |
| `deployment.pluginContainer.image.registry`        | Image registry, eg. `docker.io`.                                                                           | `docker.io`                                 |
| `deployment.pluginContainer.image.repository`      | Image repository, eg. `curlimages/curl`.                                                                   | `curlimages/curl`                           |
| `deployment.pluginContainer.image.tag`             | Custom image tag, eg. `0.1.0`.                                                                             | `8.16.0`                                    |
| `deployment.pluginContainer.image.pullPolicy`      | Image pull policy.                                                                                         | `IfNotPresent`                              |
| `deployment.priorityClassName`                     | PriorityClassName of the Reposilite deployment.                                                            | `""`                                        |
| `deployment.replicas`                              | Number of replicas for the Reposilite deployment.                                                          | `1`                                         |
| `deployment.restartPolicy`                         | Restart policy of the Reposilite deployment.                                                               | `""`                                        |
| `deployment.securityContext`                       | Security context of the Reposilite deployment.                                                             | `{}`                                        |
| `deployment.strategy.type`                         | Strategy type - `Recreate` or `RollingUpdate`.                                                             | `RollingUpdate`                             |
| `deployment.strategy.rollingUpdate.maxSurge`       | The maximum number of pods that can be scheduled above the desired number of pods during a rolling update. | `1`                                         |
| `deployment.strategy.rollingUpdate.maxUnavailable` | The maximum number of pods that can be unavailable during a rolling update.                                | `1`                                         |
| `deployment.terminationGracePeriodSeconds`         | How long to wait until forcefully kill the pod.                                                            | `60`                                        |
| `deployment.tolerations`                           | Tolerations of the Reposilite deployment.                                                                  | `[]`                                        |
| `deployment.topologySpreadConstraints`             | TopologySpreadConstraints of the Reposilite deployment.                                                    | `[]`                                        |
| `deployment.volumes`                               | Additional volumes to mount into the pods of the reposilite deployment.                                    | `[]`                                        |

### Horizontal Pod Autoscaler (HPA)

| Name                     | Description                                                                                        | Value       |
| ------------------------ | -------------------------------------------------------------------------------------------------- | ----------- |
| `hpa.enabled`            | Enable the horizontal pod autoscaler (HPA).                                                        | `false`     |
| `hpa.annotations`        | Additional annotations for the HPA.                                                                | `{}`        |
| `hpa.labels`             | Additional labels for the HPA.                                                                     | `{}`        |
| `hpa.behavior.scaleDown` | Scaling policy for scaling down.                                                                   |             |
| `hpa.metrics`            | Metrics contains the specifications for which to use to calculate the desired replica count.       | `undefined` |
| `hpa.minReplicas`        | Min replicas is the lower limit for the number of replicas to which the autoscaler can scale down. | `1`         |
| `hpa.maxReplicas`        | Upper limit for the number of pods that can be set by the autoscaler.                              | `10`        |

### Ingress

| Name                  | Description                                                                                     | Value   |
| --------------------- | ----------------------------------------------------------------------------------------------- | ------- |
| `ingress.enabled`     | Enable creation of an ingress resource. Requires, that the http service is also enabled.        | `false` |
| `ingress.className`   | Ingress class.                                                                                  | `nginx` |
| `ingress.annotations` | Additional ingress annotations.                                                                 | `{}`    |
| `ingress.labels`      | Additional ingress labels.                                                                      | `{}`    |
| `ingress.hosts`       | Ingress specific configuration. Let ingress controller listen on specific DNS names and path's. | `[]`    |
| `ingress.tls`         | Ingress specific TLS configuration. Use TLS encryption for specific hostnames.                  | `[]`    |

### Network Policy

| Name                        | Description                                                               | Value   |
| --------------------------- | ------------------------------------------------------------------------- | ------- |
| `networkPolicy.enabled`     | Enable network policies in general.                                       | `false` |
| `networkPolicy.annotations` | Additional network policy annotations.                                    | `{}`    |
| `networkPolicy.labels`      | Additional network policy labels.                                         | `{}`    |
| `networkPolicy.policyTypes` | List of policy types. Supported is ingress, egress or ingress and egress. | `[]`    |
| `networkPolicy.egress`      | Concrete egress network policy implementation.                            | `[]`    |
| `networkPolicy.ingress`     | Concrete ingress network policy implementation.                           | `[]`    |

### Persistent Volume Claim

| Name                                                       | Description                                                                                                                                                                                          | Value           |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `persistentVolumeClaim.enabled`                            | Enable persistence in general.                                                                                                                                                                       | `false`         |
| `persistentVolumeClaim.path`                               | Path where the persistent volume claim should be mounted into the container file system.                                                                                                             | `/app/data`     |
| `persistentVolumeClaim.existing.enabled`                   | Enable an existing persistent volume claim.                                                                                                                                                          | `false`         |
| `persistentVolumeClaim.existing.persistentVolumeClaimName` | Name of the existing persistent volume claim.                                                                                                                                                        | `""`            |
| `persistentVolumeClaim.new.annotations`                    | Additional service account annotations.                                                                                                                                                              | `{}`            |
| `persistentVolumeClaim.new.labels`                         | Additional service account labels.                                                                                                                                                                   | `{}`            |
| `persistentVolumeClaim.new.accessMode`                     | Access mode of the persistent volume claim. More information about the access modes are in detail documented [online](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes). | `ReadWriteOnce` |
| `persistentVolumeClaim.new.size`                           | Size of the persistent volume claim.                                                                                                                                                                 | `10Gi`          |
| `persistentVolumeClaim.new.storageClass`                   | Custom storage class. Left it empty to use the clusters default storage class.                                                                                                                       | `""`            |

### Prometheus

| Name                                                      | Description                                                                                                                                  | Value      |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `prometheus.metrics.enabled`                              | Enable of scraping metrics by Prometheus.                                                                                                    | `false`    |
| `prometheus.metrics.secret.existing.enabled`              | Use an existing secret containing the basic auth credentials.                                                                                | `false`    |
| `prometheus.metrics.secret.existing.secretName`           | Name of the secret containing the basic auth credentials.                                                                                    | `""`       |
| `prometheus.metrics.secret.existing.basicAuthUsernameKey` | Name of the key in the secret that contains the username for basic auth.                                                                     | `""`       |
| `prometheus.metrics.secret.existing.basicAuthPasswordKey` | Name of the key in the secret that contains the password for basic auth.                                                                     | `""`       |
| `prometheus.metrics.secret.new.annotations`               | Additional secret annotations.                                                                                                               | `{}`       |
| `prometheus.metrics.secret.new.labels`                    | Additional secret labels.                                                                                                                    | `{}`       |
| `prometheus.metrics.secret.new.basicAuthUsername`         | Username for basic auth. The username and password is required by reposilite to expose metrics. Default: random alpha numeric string.        | `""`       |
| `prometheus.metrics.secret.new.basicAuthPassword`         | Password for basic auth. The username and password is required by reposilite to expose metrics. Default random alpha numeric string.         | `""`       |
| `prometheus.metrics.podMonitor.enabled`                   | Enable creation of a podMonitor. Excludes the existence of a serviceMonitor resource.                                                        | `false`    |
| `prometheus.metrics.podMonitor.annotations`               | Additional podMonitor annotations.                                                                                                           | `{}`       |
| `prometheus.metrics.podMonitor.enableHttp2`               | Enable HTTP2.                                                                                                                                | `false`    |
| `prometheus.metrics.podMonitor.followRedirects`           | FollowRedirects configures whether scrape requests follow HTTP 3xx redirects.                                                                | `false`    |
| `prometheus.metrics.podMonitor.honorLabels`               | Honor labels.                                                                                                                                | `false`    |
| `prometheus.metrics.podMonitor.labels`                    | Additional podMonitor labels.                                                                                                                | `{}`       |
| `prometheus.metrics.podMonitor.interval`                  | Interval at which metrics should be scraped. If not specified Prometheus' global scrape interval is used.                                    | `60s`      |
| `prometheus.metrics.podMonitor.path`                      | HTTP path of the Reposilite pod for scraping Prometheus metrics.                                                                             | `/metrics` |
| `prometheus.metrics.podMonitor.port`                      | HTTP port of the Reposilite pod for scraping Prometheus metrics.                                                                             | `http`     |
| `prometheus.metrics.podMonitor.relabelings`               | RelabelConfigs to apply to samples before scraping. Prometheus Operator automatically adds relabelings for a few standard Kubernetes fields. | `[]`       |
| `prometheus.metrics.podMonitor.scrapeTimeout`             | Timeout after which the scrape is ended. If not specified, global Prometheus scrape timeout is used.                                         | `30s`      |
| `prometheus.metrics.podMonitor.scheme`                    | HTTP scheme to use for scraping. For example `http` or `https`.                                                                              | `http`     |
| `prometheus.metrics.podMonitor.tlsConfig`                 | TLS configuration to use when scraping the metric endpoint by Prometheus.                                                                    | `{}`       |
| `prometheus.metrics.serviceMonitor.enabled`               | Enable creation of a serviceMonitor. Excludes the existence of a podMonitor resource.                                                        | `false`    |
| `prometheus.metrics.serviceMonitor.annotations`           | Additional serviceMonitor annotations.                                                                                                       | `{}`       |
| `prometheus.metrics.serviceMonitor.labels`                | Additional serviceMonitor labels.                                                                                                            | `{}`       |
| `prometheus.metrics.serviceMonitor.enableHttp2`           | Enable HTTP2.                                                                                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.followRedirects`       | FollowRedirects configures whether scrape requests follow HTTP 3xx redirects.                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.honorLabels`           | Honor labels.                                                                                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.interval`              | Interval at which metrics should be scraped. If not specified Prometheus' global scrape interval is used.                                    | `60s`      |
| `prometheus.metrics.serviceMonitor.path`                  | HTTP path for scraping Prometheus metrics.                                                                                                   | `/metrics` |
| `prometheus.metrics.serviceMonitor.relabelings`           | RelabelConfigs to apply to samples before scraping. Prometheus Operator automatically adds relabelings for a few standard Kubernetes fields. | `[]`       |
| `prometheus.metrics.serviceMonitor.scrapeTimeout`         | Timeout after which the scrape is ended. If not specified, global Prometheus scrape timeout is used.                                         | `30s`      |
| `prometheus.metrics.serviceMonitor.scheme`                | HTTP scheme to use for scraping. For example `http` or `https`.                                                                              | `http`     |
| `prometheus.metrics.serviceMonitor.tlsConfig`             | TLS configuration to use when scraping the metric endpoint by Prometheus.                                                                    | `{}`       |

### Service

| Name                               | Description                                                                                                                                                                                                | Value       |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `service.enabled`                  | Enable the service.                                                                                                                                                                                        | `true`      |
| `service.annotations`              | Additional service annotations.                                                                                                                                                                            | `{}`        |
| `service.externalIPs`              | External IPs for the service.                                                                                                                                                                              | `[]`        |
| `service.externalTrafficPolicy`    | If `service.type` is `NodePort` or `LoadBalancer`, set this to `Local` to tell kube-proxy to only use node local endpoints for cluster external traffic. Furthermore, this enables source IP preservation. | `Cluster`   |
| `service.internalTrafficPolicy`    | If `service.type` is `NodePort` or `LoadBalancer`, set this to `Local` to tell kube-proxy to only use node local endpoints for cluster internal traffic.                                                   | `Cluster`   |
| `service.ipFamilies`               | IPFamilies is list of IP families (e.g. `IPv4`, `IPv6`) assigned to this service. This field is usually assigned automatically based on cluster configuration and only required for customization.         | `[]`        |
| `service.labels`                   | Additional service labels.                                                                                                                                                                                 | `{}`        |
| `service.loadBalancerClass`        | LoadBalancerClass is the class of the load balancer implementation this Service belongs to. Requires service from type `LoadBalancer`.                                                                     | `""`        |
| `service.loadBalancerIP`           | LoadBalancer will get created with the IP specified in this field. Requires service from type `LoadBalancer`.                                                                                              | `""`        |
| `service.loadBalancerSourceRanges` | Source range filter for LoadBalancer. Requires service from type `LoadBalancer`.                                                                                                                           | `[]`        |
| `service.port`                     | Port to forward the traffic to.                                                                                                                                                                            | `8080`      |
| `service.scheme`                   | Name of the service port. This name is also used as scheme / port name of the service monitor resource.                                                                                                    | `http`      |
| `service.sessionAffinity`          | Supports `ClientIP` and `None`. Enable client IP based session affinity via `ClientIP`.                                                                                                                    | `None`      |
| `service.sessionAffinityConfig`    | Contains the configuration of the session affinity.                                                                                                                                                        | `{}`        |
| `service.type`                     | Kubernetes service type for the traffic.                                                                                                                                                                   | `ClusterIP` |

### ServiceAccount

| Name                                              | Description                                                                                                                                         | Value   |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `serviceAccount.existing.enabled`                 | Use an existing service account instead of creating a new one. Assumes that the user has all the necessary kubernetes API authorizations.           | `false` |
| `serviceAccount.existing.serviceAccountName`      | Name of the existing service account.                                                                                                               | `""`    |
| `serviceAccount.new.annotations`                  | Additional service account annotations.                                                                                                             | `{}`    |
| `serviceAccount.new.labels`                       | Additional service account labels.                                                                                                                  | `{}`    |
| `serviceAccount.new.automountServiceAccountToken` | Enable/disable auto mounting of the service account token.                                                                                          | `true`  |
| `serviceAccount.new.imagePullSecrets`             | ImagePullSecrets is a list of references to secrets in the same namespace to use for pulling any images in pods that reference this serviceAccount. | `[]`    |
| `serviceAccount.new.secrets`                      | Secrets is the list of secrets allowed to be used by pods running using this ServiceAccount.                                                        | `[]`    |
