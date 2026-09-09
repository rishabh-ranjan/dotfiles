# AWS

An AWS ParallelCluster named `roach` in us-east-1 (account 851687812557,
the Amazon AI Fellowship's credits). Code: `roach.slurm.clusters.aws`
(`AWS`, `H100`, `H100_SPOT`, `A100`, `A100_SPOT`, `A10G`); the cluster itself is
`roach/slurm/clusters/aws/cluster.yaml`, driven by `pcluster.sh` next to it.
Monitor: [`scripts/aws-watch.sh`](../scripts/aws-watch.sh).

**Only on the human's instruction, and only the node count the human
gave.** The shape is `H100` (a p5.48xlarge) unless the instruction names
another: per dollar it does the most work. Every node-hour is dollars off a
finite pool of credits, which do not apply retroactively: usage past the
balance bills the human's card. There is no tier to fill and no free card
to find.

## Remote

The session never runs on AWS. `AWS.submit_host="aws"` makes `submit()` and
`Job.state` go over `ssh aws` (the alias in `~/.ssh/config`: the head node's
elastic IP, user `ubuntu`, key `~/scratch/.secrets/aws_ssh`; no gate, no
ControlMaster needed). `$A` below is `ssh -o BatchMode=yes aws`. The AWS
CLI here reads its credentials from `~/scratch/.secrets/aws` (an env file:
`set -a; . ~/scratch/.secrets/aws; set +a` before any `aws` or `pcluster`
command); there is no `~/.aws`.

## Nodes and storage

The head node is a `t3.medium`, permanent, ~$30/month plus the NAT gateway
and the FSx volume (~$200/month together). Compute nodes exist only while a
job holds them: slurm asks EC2 for one when a job is queued (2-5 minutes to
boot), and ParallelCluster terminates it 5 minutes after it goes idle.

| queue | instance | cards | vCPUs | memory | billing |
| --- | --- | --- | --- | --- | --- |
| `h100` | p5.48xlarge | 8 x H100-80G | 192 | 2 TB | on demand, ~$55/h |
| `h100-spot` | p5.48xlarge | same | | | spot, reclaimed with 120 s notice |
| `a100` | p4d.24xlarge | 8 x A100-40G | 96 | 1.1 TB | on demand, ~$33/h |
| `a100-spot` | p4d.24xlarge | same | | | spot |
| `a10g` | g5.12xlarge | 4 x A10G-24G | 48 | 192 GB | on demand, ~$5.7/h; probes and debugging, 1 node |

Up to 4 nodes per queue (`MaxCount` in `cluster.yaml`; raise it and the EC2
quota together). All in one AZ (us-east-1d) with EFA and a placement group,
so multi-node jobs get the fast interconnect.

| path | what | use for |
| --- | --- | --- |
| `~` = `/fsx/home/ubuntu` | the roach home on FSx Lustre, shared by every node | pixi, `~/roach_clones` |
| `~/scratch` -> `/fsx/scratch/ubuntu` | the same FSx, 1.2 TB (`SCRATCH_2`, no backup) | logs, checkpoints, data, `.secrets` |
| `/scratch` | the instance's NVMe, formatted at boot | `TMPDIR`; gone with the instance |
| `/home/ubuntu` | the head node's disk, NFS-exported | nothing |

**FSx is scratch-class storage with no backup**: a `pcluster delete-cluster`
deletes it. Anything worth keeping is copied off (to S3, or here) before
the cluster is torn down.

## Read the cluster, every submission

```
$A squeue -o "%.8i %.30j %.12P %.9T %.10M %R"                 # yours, with reasons
$A sinfo -o "%P %D %t %E"                                       # what is up, and why a node is down
set -a; . ~/scratch/.secrets/aws; set +a
aws ce get-cost-and-usage --time-period Start=$(date +%Y-%m-01),End=$(date -d tomorrow +%Y-%m-%d) \
    --granularity MONTHLY --metrics UnblendedCost --query 'ResultsByTime[0].Total.UnblendedCost.Amount'   # this month's gross spend
aws service-quotas get-service-quota --service-code ec2 --quota-code L-417A185B --query Quota.Value        # P-instance vCPU quota (192 per p5/p4d node)
```

A pending job here is EC2 not handing over a node, not a queue: the reason
reads `Resources`/`Priority` while ParallelCluster launches, and stays there
if EC2 has no capacity (`InsufficientInstanceCapacity` in
`$A sudo tail /var/log/parallelcluster/clustermgtd`) or the quota is 0. p5 on
demand is often unavailable; `h100-spot`, `a100`, or a Capacity Block are
the alternatives, and the human picks. A spot node reclaimed mid-run shows as
a job back in PENDING with `Restarts>0`: it resumes from its checkpoint, if
it has one.

## Resource shapes

The presets are whole nodes (`gpus="8"`, `exclusive=True`, no account, no
qos: ParallelCluster runs no accounting). `nodes=N` up to 4. Smaller jobs
(`gpus="1"`) still pay for the whole instance, since a node is launched per
job and the queues are one instance type: there is no cheaper card to fall
back on, so pack work into whole nodes.

## Cluster lifecycle

```
roach/slurm/clusters/aws/pcluster.sh status | create | update | setup | delete
```

`update` applies `cluster.yaml` (queues drain first). `setup` runs once after
`create`: it makes the FSx homes, copies the secrets, and points the head
node's login at `/fsx` and `/opt/slurm/bin`, then prints the ssh alias to
put in `~/.ssh/config`. Quota increases (P-instance on-demand and spot vCPUs,
`L-417A185B` / `L-7212CCBC`) are filed in Service Quotas and take days.
