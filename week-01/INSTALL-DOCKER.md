# Installing Docker CE on Rocky Linux 9.6

This guide walks you through installing Docker Community Edition on a Rocky Linux 9.6 VM. If you're using GitHub Codespaces, skip this—Docker is already installed.

---

## Prerequisites

- Rocky Linux 9.6 VM with sudo access
- Internet connectivity
- At least 2GB RAM, 10GB disk space

---

## Step 1: Remove Old Docker Versions (if any)

If you have older Docker packages installed, remove them first:

```bash
sudo dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    podman \
    runc
```

> **Note:** Rocky Linux 9.6 comes with Podman by default. We're removing it to avoid confusion, though Docker and Podman can coexist.

---

## Step 2: Install Required Packages

Install `dnf-plugins-core` to manage repositories:

```bash
sudo dnf install -y dnf-plugins-core
```

---

## Step 3: Add the Docker Repository

Add the official Docker CE repository:

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
```

> **Why RHEL repo?** Rocky Linux 9 is binary-compatible with RHEL 9, so the RHEL Docker packages work perfectly. For Rocky 9.x, we use the RHEL repository instead of CentOS.

---

## Step 4: Install Docker CE

Install Docker Engine, CLI, containerd, and Compose plugin:

```bash
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

When prompted about GPG keys, verify the fingerprint matches:
```
060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35
```

Type `y` to accept.

---

## Step 5: Start and Enable Docker

Start the Docker service and enable it to start on boot:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

Verify it's running:

```bash
sudo systemctl status docker
```

You should see `active (running)` in green.

---

## Step 6: Add Your User to the Docker Group

By default, Docker requires root. Add your user to the `docker` group to run without `sudo`:

```bash
sudo usermod -aG docker $USER
```

**Important:** Log out and log back in for this to take effect, or run:

```bash
newgrp docker
```

---

## Step 7: Verify Installation

Test that Docker works without sudo:

```bash
docker --version
docker run hello-world
```

Expected output:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

Also verify Docker Compose:

```bash
docker compose version
```

---

## Troubleshooting

### "Permission denied" when running docker

You either:
1. Didn't add your user to the docker group
2. Didn't log out and back in after adding

Fix:
```bash
sudo usermod -aG docker $USER
# Then log out and log back in
```

### Docker service won't start

Check the logs:
```bash
sudo journalctl -u docker.service -n 50
```

Common causes:
- Conflicting container runtime (podman)
- Disk space issues
- SELinux blocking (check with `sudo ausearch -m avc -ts recent`)

### "No space left on device"

Docker stores images and containers in `/var/lib/docker`. Check disk space:

```bash
df -h /var/lib/docker
```

Clean up unused resources:
```bash
docker system prune -a
```

### SELinux Issues

If you see SELinux denials, you have options:

**Option 1:** Set SELinux to permissive (not recommended for production):
```bash
sudo setenforce 0
```

**Option 2:** Install Docker SELinux policy (usually pre-installed on Rocky 9.6):
```bash
sudo dnf install -y container-selinux
```

**Note:** Rocky Linux 9.6 typically has better SELinux integration with containers out of the box.

---

## Optional: Configure Docker

### Change Docker's Storage Location

If you want Docker to store data on a different disk:

1. Stop Docker:
   ```bash
   sudo systemctl stop docker
   ```

2. Create/edit `/etc/docker/daemon.json`:
   ```json
   {
     "data-root": "/path/to/new/location"
   }
   ```

3. Move existing data (if any):
   ```bash
   sudo mv /var/lib/docker /path/to/new/location
   ```

4. Start Docker:
   ```bash
   sudo systemctl start docker
   ```

### Enable Live Restore

Keep containers running when Docker daemon restarts:

Edit `/etc/docker/daemon.json`:
```json
{
  "live-restore": true
}
```

Restart Docker:
```bash
sudo systemctl restart docker
```

---

## Verification Checklist

Before proceeding to the labs, verify:

- [ ] `docker --version` shows Docker version 24.x or newer (25.x recommended for Rocky 9.6)
- [ ] `docker compose version` shows Compose v2.x
- [ ] `docker run hello-world` works without sudo
- [ ] `docker ps` returns an empty list (no errors)

---

## Next Steps

Return to the [Week 1 README](./README.md) and proceed to Lab 1.
