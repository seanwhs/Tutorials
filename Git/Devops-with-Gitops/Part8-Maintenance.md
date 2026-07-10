# Part 8: Scale & Maintenance

**Module Goal:** Move beyond GitHub-hosted runners' free-tier limits by building self-hosted runners in Docker, understand when and why to do this, and manage them safely at scale.

> **Note:** This part is written in structural/prose form rather than literal fenced code blocks, due to a recurring note-tool parsing error with nested code fences in this session. If you want it converted into full literal Dockerfile/YAML code blocks like Parts 1–3 and 6, just ask and I'll regenerate it.

---

## 1. Concept Explanation

### Why Self-Hosted Runners

GitHub-hosted runners are free but rate-limited: a fixed number of included minutes per month on private repos, capped concurrency, and generic hardware. Self-hosted runners are your own compute (a laptop, a home server, a cheap VPS, a Kubernetes cluster) registered to your repo or org, running the same Actions runner agent. Three reasons a Principal Engineer reaches for this: cost at scale (unlimited minutes on hardware you already own), performance (persistent local Docker layer cache and dependency cache across every single run, not just within one job's cache-restore step), and access (a runner living inside your private network, able to reach internal-only resources a cloud-hosted runner never could).

### The Security Tradeoff You Must Accept

A self-hosted runner is a security tradeoff, not a free upgrade. Anyone able to open a pull request against a public repo can make a self-hosted runner execute arbitrary code from their branch, unless carefully restricted. The non-negotiable rule: never attach self-hosted runners to public repositories without restricting workflow runs from fork pull requests to require prior approval (Settings → Actions → General → Fork pull request workflows from outside collaborators → require approval for all outside collaborators). For private repos with trusted contributors this risk is much lower but not zero — treat every self-hosted runner as a privileged, network-connected execution environment, not a disposable sandbox.

---

## 2. Implementation

### Step 1 — The Runner Container

A self-hosted runner is just a Docker container running GitHub's actions-runner agent, registered to your repo with a short-lived registration token, listening for jobs.

**Dockerfile contents, conceptually:** base image `ubuntu:22.04`, install `curl`, `jq`, `git`, and `docker.io` as prerequisites (`docker.io` only if you want docker-in-docker build support inside the runner itself, needed to replicate the Part 3 Docker build workflow on self-hosted infrastructure), download the `actions-runner` release tarball matching the target architecture from GitHub's releases API, extract it, run the included dependency installer script, create a non-root user named `runner`, and set an entrypoint script that runs the registration command using environment variables for the repository URL and a runner token, then hands off to `run.sh`, the runner agent's own foreground process.

**The entrypoint script's core logic:** call `config.sh` with the `--url` flag pointing at the repository or organization, the `--token` flag using a value fetched fresh at container start (never baked into the image) from a registration endpoint, `--labels` flag set to a comma-separated list such as `self-hosted,linux,x64,docker-cache` identifying this runner's capabilities so workflows can target it specifically, and `--unattended` to skip interactive prompts, followed by `exec ./run.sh` to start listening for jobs.

### Step 2 — Registration Token Handling, Done Correctly

The registration token is short-lived, typically valid for one hour, and must be generated via the GitHub API using a Personal Access Token or, better, a GitHub App installation token with the `administration:write` permission scoped to the specific repo. The entrypoint script calls the API's create-registration-token endpoint for a runner at container startup, ensuring every container start gets a fresh token rather than relying on a stale one baked in at image build time — the same "never bake secrets into images" principle from Part 3's security note about layer inspection.

### Step 3 — Running Multiple Ephemeral Runners with Docker Compose

Rather than one long-lived runner container handling job after job (which risks state leaking between unrelated jobs' filesystems, a real security concern), the recommended pattern runs **ephemeral runners**: each container registers, picks up exactly one job, and then exits and is destroyed, with a supervisor process spinning up a fresh replacement container immediately after.

A `docker-compose.yml` defining a `runner` service with a build context pointing at the Dockerfile above, environment variables for `REPO_URL` and a `GITHUB_PAT` used only to mint fresh registration tokens (never the long-lived PAT itself passed to `config.sh`), an ephemeral flag added to the `config.sh` invocation via an `EPHEMERAL` environment variable read by the entrypoint script, a restart policy of `on-failure` so the compose orchestrator relaunches a fresh container automatically the moment the previous one exits after completing its single job, and a `deploy replicas` setting (in Swarm mode) or simply multiple named services (in plain Compose) to run several runners in parallel, each an isolated, disposable execution environment.

### Step 4 — Targeting Self-Hosted Runners from a Workflow

Any existing workflow from Parts 1 through 7 can be redirected to self-hosted infrastructure by changing exactly one line, `runs-on`, from `ubuntu-latest` to a matching label such as `self-hosted`, or the more specific label set defined in Step 1, for example `[self-hosted, linux, x64, docker-cache]`. No other change to the workflow YAML is required — this is precisely why the `runs-on` abstraction exists, the rest of the pipeline (checkout, setup, build, test, deploy) is completely portable between hosted and self-hosted execution.

### Step 5 — Scaling Further with Kubernetes: Actions Runner Controller

For organizations outgrowing a handful of Docker Compose runners on one VPS, the free, open-source **Actions Runner Controller (ARC)** project runs as a Kubernetes operator, automatically scaling the number of runner pods up and down based on the actual queued job count in your repo or org, rather than a fixed number of always-on containers. ARC is installed via a Helm chart, configured with a `RunnerScaleSet` custom resource specifying the minimum and maximum runner replica count, the container image to use (the same Dockerfile pattern from Step 1, adapted to ARC's expected entrypoint contract), and the GitHub App credentials ARC uses to register and deregister runners automatically as demand rises and falls — giving you elastic, cost-proportional-to-actual-usage self-hosted capacity without manually managing individual containers.

### Step 6 — Maintenance Workflow

A scheduled workflow, `runner-maintenance.yml`, running weekly, connects to the self-hosted fleet (via SSH or a Kubernetes job, depending on Step 3 vs Step 5 architecture) to prune stale Docker images and build cache accumulated across many job runs (`docker system prune` with an age filter), verify each runner's agent software is on the latest supported release (GitHub deprecates old runner versions and will eventually refuse jobs from very outdated agents), and reports fleet health — count of active runners, oldest agent version in the fleet, and available disk space — through the same `notify.yml` reusable workflow built in Part 7, because a silently degrading self-hosted fleet is exactly the kind of slow failure observability is meant to catch before it becomes an outage.

---

## 3. Exercise Challenge

1. Modify the ephemeral runner entrypoint so that if job pickup fails five consecutive times (a sign the registration token minting step itself is broken, not the job), the container exits with a distinct error code that a monitoring wrapper can distinguish from a normal single-job completion exit.
2. Write the `RunnerScaleSet` configuration values needed for ARC to enforce a maximum of 10 concurrent runner pods, protecting the underlying Kubernetes cluster's node pool from being overwhelmed by a burst of queued jobs (for example, from a matrix build across many OS and version combinations, as built in Part 2).
3. Explain, in the specific context of a self-hosted runner used to run the Part 3 Docker build workflow, why running a container that itself needs to build other containers (docker-in-docker) introduces additional security considerations beyond what a GitHub-hosted runner requires, and propose a mitigation.

---

## 4. Solution & Explanation

**Item 1:** The entrypoint script maintains a simple counter file inside the container's own ephemeral filesystem, incremented each time the registration token fetch or `config.sh` call fails before ever reaching `run.sh`, and checked at the top of each retry attempt; on the fifth consecutive failure the script exits with code `78` (a value deliberately unlikely to collide with any exit code a real job's own command might produce), which the outer supervisor (the maintenance workflow from Step 6, or a simple bash loop restarting the compose service) treats as "registration is broken, page someone" rather than "a job simply finished and needs a replacement," triggering escalation through `notify.yml` instead of silently spinning up replacement container after replacement container against a broken token endpoint.

**Item 2:** The `RunnerScaleSet` resource's spec includes a `maxRunners` field set to `10` and a `minRunners` field, commonly set to `0` or `1` depending on whether you want zero idle cost during quiet periods or one warm runner to avoid cold-start latency on the very next job. Setting `maxRunners` caps ARC's autoscaling ceiling regardless of how many jobs are queued, so a burst of 40 queued matrix jobs from a Part 2-style matrix build will queue 10 at a time rather than requesting 40 simultaneous pods against the cluster's node pool — trading some throughput for protecting the shared cluster's stability, a deliberate and often correct tradeoff for a self-hosted fleet shared across multiple teams' repos.

**Item 3:** GitHub-hosted runners provide Docker as a pre-configured, isolated capability with no special privilege granted to your job beyond using it; a self-hosted runner attempting the same Docker-build-in-CI workflow from Part 3 typically needs the container running the runner agent itself to have access to a Docker daemon, most simply achieved by mounting the host's Docker socket into the runner container. This is a materially larger privilege grant than it appears: any process able to talk to that mounted socket can, in practice, execute commands on the host with root-equivalent privilege, meaning a malicious or compromised job running on that runner could escape the container entirely. The mitigation is to avoid the naive host-socket-mount pattern and instead run an isolated, ephemeral Docker-in-Docker sidecar (the `dind` image) scoped to only that single job's lifetime and destroyed immediately after, so even a fully compromised build step only ever has access to a throwaway Docker daemon with no path back to the actual host machine — combined with the ephemeral single-job-per-container pattern from Step 3 so no state or credentials persist between one job and the next.

---

**This concludes the eight-part series.** Continue to the **"DevOps Mastery - Appendices A B C"** note for the codebase reference file tree, the DevOps decision matrix, and the OIDC setup checklist.
