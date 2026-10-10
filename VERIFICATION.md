# Recorded verification

## Original → unchanged copy → composition

The prior remote-source adapter passed seven native mocked-plan runs containing 33 assertions. A historical negative check shifted a private subnet's route-table association index: the intended disabled/per-AZ checks failed, then all three binding runs passed after exact source restoration. Those records were preserved, not rerun or overwritten.

The new local copy preserves all 111 tracked files from the same pinned commit. Every raw file matches its Git blob identity, byte hash and recorded `100644` mode. The native Linux copy used `0644`. The copied source and provider lock remained unchanged after execution.

The composed adapter was run in fresh Linux working and data directories. Its root fixture and all three direct-binding modules resolved to the copied local source. Formatting, initialization with the read-only lock, validation and the full suite passed:

| Test file | Passing runs |
| --- | --- |
| `tests/bindings.tftest.hcl` | `disabled_bindings`, `shared_bindings`, `per_az_bindings` |
| `tests/modes.tftest.hcl` | `disabled_by_default`, `shared`, `per_az`, `reject_unknown_nat_mode` |

The invalid-mode run expects the input validation failure. All seven runs are explicit plans with refresh disabled and an AWS mock provider. The suite has 33 assertion blocks. [Recorded output](verification-output.txt) and [verification-summary.json](verification-summary.json) retain the result.

## Environment and limits

Observed runtime: OpenTofu 1.13.0, AWS provider 6.28.0, Linux amd64 under Ubuntu 24.04/WSL2. Initialization reused an existing filesystem provider mirror. That local record did not verify a fresh provider download.

Checked on **2026-10-11 (JST)**: [GitHub Actions run 38060125051](https://github.com/skyon0522-ai/aws-vpc-topology-contracts/actions/runs/38060125051) passed for commit [`5e29c5049a3fb2a7b6642036ea510249167e3497`](https://github.com/skyon0522-ai/aws-vpc-topology-contracts/commit/5e29c5049a3fb2a7b6642036ea510249167e3497). All workflow jobs succeeded, including initialization, validation, and the seven mocked-plan tests. This is remote CI evidence for the linked commit, not deployed AWS connectivity or production behavior.

The local runner removed inherited AWS/Terraform/OpenTofu settings, used absent task-owned credential/configuration files and a task-local CLI configuration, and disabled metadata/checkpoint requests. No apply, destroy or deployed AWS operation was executed.

Mocks supply computed identifiers; configuration determines counts and route relationships. The private/intra public-IP checks reject `true`; the optional upstream attribute remains null. This does not verify AWS defaults, packet reachability, security isolation, cost, availability or failure recovery. Native Windows execution and the complete upstream development workflow are unverified.
