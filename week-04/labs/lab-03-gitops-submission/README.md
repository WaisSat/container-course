# Lab 3: Deploy to Dev and Prod

**Time:** 30 minutes
**Objective:** Deploy your app to two namespaces — dev and prod — on the shared cluster by submitting Kubernetes manifests to the infrastructure repo via GitOps

---

## How This Works

Instead of deploying to a single shared namespace, you now own two isolated namespaces on the real cluster. You fork the infrastructure repo, scaffold manifests, and open a PR. After merge, ArgoCD deploys your app to both environments automatically.

```
  You (local)                    GitHub                     Shared Cluster
  ──────────                    ──────                     ──────────────

  1. Build image ──────────►  2. Push to GHCR
                                     │
  3. Fork talos-gitops         4. Scaffold manifests
     Create branch                  for dev/ and prod/
          │                          │
          └──────────────────► 5. Open PR to
                                  talos-gitops
                                     │
                              6. PR merged ──────────►  7. ArgoCD syncs
                                                              │
                                                     8. Two namespaces created:
                                                        student-<you>-dev
                                                        student-<you>-prod
```

Your directory in `talos-gitops` looks like this:

```
student-infra/students/<username>/
  kustomization.yaml         # points to dev/ and prod/
  dev/
    kustomization.yaml       # sets namespace: student-<username>-dev
    namespace.yaml
    deployment.yaml
    service.yaml
  prod/
    kustomization.yaml       # sets namespace: student-<username>-prod
    namespace.yaml
    deployment.yaml
    service.yaml
```

Each environment's `kustomization.yaml` uses the Kustomize namespace transformer — the individual manifests don't hardcode a namespace. Dev and prod are identical copies for now (we'll learn how to eliminate that duplication with Kustomize overlays in a later week).

> **Reference:** The instructor's directory at `student-infra/students/jlgore/` is a complete working example. Look at it whenever you're unsure about a field or structure.

---

## Part 1: Push Your Image to GHCR

You did this in Week 1, but now with the v4 tag:

```bash
cd week-04/labs/lab-02-deploy-and-scale/starter

# Tag for GHCR
docker tag student-app:v4 ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4

# Log in to GHCR (use a Personal Access Token with packages:write scope)
echo $GITHUB_TOKEN | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin

# Push
docker push ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4
```

> **Codespace users:** The default `$GITHUB_TOKEN` in GitHub Codespaces does **not** have permission to create packages in the org. You'll get `permission_denied: installation not allowed to Create organization package`. To fix this, create a **Personal Access Token (classic)** at [Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens) with the `write:packages` scope, then log in with that instead:
>
> ```bash
> echo "ghp_YOUR_TOKEN_HERE" | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin
> ```

### Make It Public

Your image must be publicly pullable so the shared cluster can access it without credentials:

1. Go to `https://github.com/<YOUR_USERNAME>?tab=packages`
2. Click on `container-course-app`
3. **Package settings** → **Danger zone** → Change visibility to **Public**

---

## Part 2: Fork and Clone talos-gitops

You have triage access to the infrastructure repo. Fork it so you can push a branch:

1. Go to [github.com/ziyotek-edu/talos-gitops](https://github.com/ziyotek-edu/talos-gitops) and click **Fork**
2. Clone your fork:

```bash
cd ~/
git clone https://github.com/<YOUR_GITHUB_USERNAME>/talos-gitops.git
cd talos-gitops
git checkout -b week04/<YOUR_GITHUB_USERNAME>
```

---

## Part 3: Create Your Directory and Scaffold Manifests

### Create the directory structure

```bash
mkdir -p student-infra/students/<YOUR_GITHUB_USERNAME>/dev
mkdir -p student-infra/students/<YOUR_GITHUB_USERNAME>/prod
```

### Scaffold with kubectl

Use `kubectl create --dry-run=client -o yaml` to generate starting manifests. You'll do this for both dev and prod.

**Dev namespace:**

```bash
cd student-infra/students/<YOUR_GITHUB_USERNAME>/dev

kubectl create namespace student-<YOUR_GITHUB_USERNAME>-dev \
  --dry-run=client -o yaml > namespace.yaml

kubectl create deployment student-app \
  --image=ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4 \
  --dry-run=client -o yaml > deployment.yaml

kubectl create service clusterip student-app-svc \
  --tcp=80:5000 \
  --dry-run=client -o yaml > service.yaml
```

**Prod namespace:**

```bash
cd ../prod

kubectl create namespace student-<YOUR_GITHUB_USERNAME>-prod \
  --dry-run=client -o yaml > namespace.yaml

kubectl create deployment student-app \
  --image=ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4 \
  --dry-run=client -o yaml > deployment.yaml

kubectl create service clusterip student-app-svc \
  --tcp=80:5000 \
  --dry-run=client -o yaml > service.yaml
```

### Edit the scaffolded files

The `kubectl create` output is minimal. You need to add labels, environment variables, probes, and resource limits. Open the instructor's example at `student-infra/students/jlgore/` and use it as reference.

**For each `namespace.yaml`** (dev and prod), add course labels:

```yaml
  labels:
    app.kubernetes.io/managed-by: gitops
    course.ziyotek.edu/course: container-fundamentals
    course.ziyotek.edu/environment: dev    # or "prod"
    course.ziyotek.edu/student: <YOUR_GITHUB_USERNAME>
```

**For each `deployment.yaml`** (dev and prod), add to the container spec:

- Labels: `app: student-app` and `student: <YOUR_GITHUB_USERNAME>` on both the deployment and pod template
- Environment variables: `STUDENT_NAME`, `GITHUB_USERNAME`, `APP_VERSION`, plus `ENVIRONMENT` using a field reference to `metadata.namespace` (so it auto-detects dev vs prod)
- Pod metadata injection: `POD_NAME`, `POD_NAMESPACE`, `POD_IP`, `NODE_NAME` via `fieldRef`
- Resource limits: 64Mi/256Mi memory, 50m/200m CPU
- Health probes: liveness and readiness on `/health` port 5000

**For each `service.yaml`** (dev and prod), add labels (`app: student-app`, `student: <YOUR_GITHUB_USERNAME>`) and make sure the selector matches `app: student-app`.

> **Key detail:** The `ENVIRONMENT` env var uses `fieldRef: metadata.namespace` instead of a hardcoded string. Kustomize sets the namespace, and the pod picks it up automatically. This is why dev and prod manifests can be identical.

### Write kustomization.yaml files

These are short — write them by hand.

**`student-infra/students/<YOUR_GITHUB_USERNAME>/kustomization.yaml`** (root — points to both envs):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - dev
  - prod
```

**`student-infra/students/<YOUR_GITHUB_USERNAME>/dev/kustomization.yaml`**:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: student-<YOUR_GITHUB_USERNAME>-dev

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
```

**`student-infra/students/<YOUR_GITHUB_USERNAME>/prod/kustomization.yaml`**:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: student-<YOUR_GITHUB_USERNAME>-prod

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
```

The `namespace:` field in each kustomization.yaml is the Kustomize namespace transformer — it automatically sets the namespace on every resource in the directory. That's why your deployment.yaml and service.yaml don't need a `metadata.namespace` field.

---

## Part 4: Register Your Directory and Validate

### Add yourself to the parent kustomization

Edit `student-infra/students/kustomization.yaml` and add your directory name to the resources list:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - jlgore
  - <YOUR_GITHUB_USERNAME>    # <-- add this line
```

### Validate with kustomize

From the repo root, run:

```bash
kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/
```

This should output valid YAML containing:
- Two Namespace resources (`student-<YOUR_GITHUB_USERNAME>-dev` and `student-<YOUR_GITHUB_USERNAME>-prod`)
- Two Deployments (one in each namespace)
- Two Services (one in each namespace)

If you get errors, compare your files to the `jlgore/` example and fix any differences.

### Verify your directory structure

```
student-infra/students/<YOUR_GITHUB_USERNAME>/
├── kustomization.yaml
├── dev/
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── prod/
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

---

## Part 5: Submit Your Pull Request

```bash
cd ~/talos-gitops
git add student-infra/students/
git commit -m "week04: add dev/prod manifests for <YOUR_GITHUB_USERNAME>"
git push origin week04/<YOUR_GITHUB_USERNAME>
```

Go to [github.com/ziyotek-edu/talos-gitops](https://github.com/ziyotek-edu/talos-gitops) and open a pull request:

- **Base:** `main`
- **Compare:** your fork's `week04/<YOUR_GITHUB_USERNAME>` branch
- **Title:** `Week 04: <YOUR_NAME> - dev/prod deployment`

Once a reviewer approves and merges, ArgoCD picks up the change and syncs both namespaces.

---

## Part 6: Watch the Deployment

After your PR is merged, ArgoCD will detect the new manifests and sync them. This usually takes 1-3 minutes.

### Verify with kubectl

```bash
# Check your dev namespace
kubectl get all -n student-<YOUR_GITHUB_USERNAME>-dev

# Check your prod namespace
kubectl get all -n student-<YOUR_GITHUB_USERNAME>-prod

# Check the pods are running in both
kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev
kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-prod

# Check logs
kubectl logs deployment/student-app -n student-<YOUR_GITHUB_USERNAME>-dev
```

### Test with port-forward

```bash
# Forward dev
kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-dev service/student-app-svc 8080:80 &
curl localhost:8080/info
kill %1

# Forward prod
kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-prod service/student-app-svc 8081:80 &
curl localhost:8081/info
kill %1
```

The `/info` endpoint should return pod metadata. Notice that `ENVIRONMENT` shows the namespace name — `student-<YOUR_GITHUB_USERNAME>-dev` or `student-<YOUR_GITHUB_USERNAME>-prod` — because it comes from `metadata.namespace`, not a hardcoded value.

---

## Checkpoint

Before you're done, verify:

- [ ] Your v4 image is on GHCR and publicly accessible
- [ ] Your `student-infra/students/<username>/` directory has the full dev+prod structure (10 files)
- [ ] `kubectl kustomize student-infra/students/<username>/` produces valid output with both namespaces
- [ ] You added your directory to `student-infra/students/kustomization.yaml`
- [ ] Your PR is submitted to `ziyotek-edu/talos-gitops` (or merged)
- [ ] After merge: pods are running in both `student-<username>-dev` and `student-<username>-prod`
- [ ] After merge: `/info` returns correct `ENVIRONMENT` in each namespace
