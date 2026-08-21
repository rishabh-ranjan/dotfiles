# Pending reasons

`squeue -u $USER -o "%.8i %.30j %.14q %.9T %R"` prints a reason beside every
pending job. Only the first two mean the queue is working.

- `Priority`, `Resources` — waiting on a card that is genuinely busy. Leave it,
  and keep watching: it still has to start.
- `ReqNodeNotAvail` (often `, May be reserved for other job`) — pinned by
  `nodelist` to a node with nothing free for you. It will sit there however
  long you leave it, because no other node can take it. Resubmit on a pool
  that has cards.
- `QOSMaxGRESPerUser`, `QOSMaxJobsPerUser`, `AssocMaxGRES` — over your own cap,
  usually behind your own other sweep. Move it to the uncapped tier or wait
  the sweep out, deliberately.
- `PartitionTimeLimit`, `QOSMaxWallDurationPerJob` — the job asks for longer
  than the qos allows and will never run. Fix the plan.
- `launch failed requeued held`, `JobHeldUser`, `JobHeldAdmin` — dead. Cancel,
  fix, resubmit.

Everything below `Resources` is a submission that did not happen.
