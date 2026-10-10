# AWS VPC topology contracts

## Problem

Check a VPC's planned outbound paths before reviewing an infrastructure change. This project compares disabled, shared and per-AZ NAT layouts using an unchanged local source copy of the actual `terraform-aws-vpc` module. Its native OpenTofu tests check resource counts and the subnet → route table → NAT gateway relationships.

The example has three availability zones, three public subnets, six private subnets and three intra subnets. The default disables NAT. Tests use a mocked AWS provider and plan operations; they require no AWS account or deployment.

Start with the [three-mode comparison](#compare-layouts) or [run commands](#run). The authored [root fixture](main.tf) selects the included [upstream module](upstream/); [mode tests](tests/modes.tftest.hcl) and [route-binding tests](tests/bindings.tftest.hcl) inspect its planned resources. [Source composition](SOURCES.md) and [observed verification](VERIFICATION.md) separate copied source, local additions and test limits.

## Demo

### Run

Use Linux amd64 with Git, curl, tar and sha256sum installed. Inside this directory, download the pinned OpenTofu binary and verify its release checksum:

```sh
set -eu
mkdir -p .tools
curl -fsSL https://github.com/opentofu/opentofu/releases/download/v1.13.0/tofu_1.13.0_linux_amd64.tar.gz -o .tools/tofu.tar.gz
printf '%s  %s\n' '1f0cb37fc85dea4e7633a72aca2332b801f72650a32be911b8b9b32907f214fb' '.tools/tofu.tar.gz' | sha256sum -c -
tar -xzf .tools/tofu.tar.gz -C .tools tofu
.tools/tofu fmt -check -recursive
.tools/tofu init -backend=false -input=false -lockfile=readonly
.tools/tofu validate
.tools/tofu test
```

Initialization loads the included `upstream` module and downloads the pinned AWS provider when it is not cached. The test files replace AWS provider operations with mocks. Each run explicitly uses `command = plan` and disables refresh.

### Compare layouts

| NAT mode | NAT gateways | Private route tables | Private NAT default routes |
| --- | ---: | ---: | ---: |
| `disabled` | 0 | 3 | 0 |
| `shared` | 1 | 1 | 1 |
| `per_az` | 3 | 3 | 3 |

The shared layout places its NAT gateway in the first public subnet. The per-AZ layout aligns public NAT placement and private routing with each subnet's availability zone. Public subnets keep a separate Internet-gateway path; disabling NAT does not remove that public path.

The `nat_mode` input accepts only these three values. A named mode prevents conflicting combinations of the upstream module's NAT flags. To change the example, keep the route-binding assertions alongside the resource-count checks and review the resulting configuration together.

## What this project adds

The upstream module defines the infrastructure resources. This repository adds a three-value `nat_mode` interface and contract tests for counts, placement and route bindings. The entire tracked source tree is preserved at commit `b3abd6df2ecf052451a361ed55b8f06f8742a795`, including its license, examples and reference workflows. [The source manifest](source-manifest.json) records 111 files, 934,669 bytes, Git blobs and file modes.

The local-source adaptation changes four module-source strings in the root fixture and three binding runs. It does not alter upstream resource logic or claim an upstream bug fix.

## Verification

The copied-source run on Linux amd64, using Ubuntu 24.04 under WSL2, passed formatting, initialization with the read-only lock file, validation and all seven native test runs. Those runs contain 33 assertions. The root fixture and three binding-test modules resolved to the included source. A fresh working/data directory reused a verified task-local AWS provider cache. Checked on **2026-10-11 (JST)**: [GitHub Actions run 38060125051](https://github.com/skyon0522-ai/aws-vpc-topology-contracts/actions/runs/38060125051) passed for commit [`5e29c5049a3fb2a7b6642036ea510249167e3497`](https://github.com/skyon0522-ai/aws-vpc-topology-contracts/commit/5e29c5049a3fb2a7b6642036ea510249167e3497). The remote run uses the committed workflow to initialize dependencies and execute mocked plans; no AWS deployment is tested. See [VERIFICATION.md](VERIFICATION.md) and the [recorded summary](verification-summary.json).

A historical negative check used a private copy of the same pinned upstream module and shifted the private route-table association index by one. The disabled and per-AZ binding runs failed on the intended association checks. After restoring the exact source bytes, all three binding runs passed. That historical check was not repeated for the new local-source full-suite run.

```text
Success! 7 passed, 0 failed.
```

## Limits

The configuration checks exercise the upstream module instead of substituting a local NAT-count calculator. Mocks supply computed identifiers; the configuration still determines resource counts, subnet placement and route targets. Native tests cover both the example's inputs and direct upstream resource relationships.

The tests reject an explicitly enabled automatic public-IP setting for private and intra subnets. Upstream leaves that optional attribute unset, so it appears as null in the mocked plan. These assertions do not verify AWS's default behavior.

These checks cover planned IPv4 configuration relationships. They do not measure deployed connectivity, failure recovery, availability, traffic, cost or the complete security posture of an AWS environment. A real deployment needs its own permissions, network tests and operational review. Windows-native runtime behavior has not been verified.

## Sources and design

- [`terraform-aws-vpc`](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/b3abd6df2ecf052451a361ed55b8f06f8742a795): 111 pinned upstream files copied unchanged into `upstream`, executed as the module resource graph.
- [Upstream NAT scenarios](https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/b3abd6df2ecf052451a361ed55b8f06f8742a795/README.md#nat-gateway-scenarios): the flag behavior and private/intra distinction used by the example.
- [OpenTofu native tests](https://opentofu.org/docs/cli/commands/test/#the-mock_provider-blocks): plan-only tests and mocked computed attributes.
- [Unearthing Semantic Checks for Cloud Infrastructure-as-Code Programs](https://www.microsoft.com/en-us/research/publication/unearthing-semantic-checks-for-cloud-infrastructure-as-code-programs/), Qiu et al., SOSP 2024: research background for checking configuration relationships beyond syntax. This project uses hand-written tests for one AWS module; it does not implement the paper's check-mining or deployment-testing system.

See [SOURCES.md](SOURCES.md) for exact versions, inspected source locations and licenses. The local example and tests use the [MIT license](LICENSE); the upstream module retains its Apache-2.0 terms.

## Security and reporting

Read [security limits and reporting guidance](SECURITY.md) before adapting this example.
