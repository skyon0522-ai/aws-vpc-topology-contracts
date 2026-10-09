# Source lineage

| Component | Pin | Role | License |
| --- | --- | --- | --- |
| terraform-aws-vpc | `b3abd6df2ecf052451a361ed55b8f06f8742a795` | Unchanged local module source in `upstream` | Apache-2.0 |
| OpenTofu | `1.13.0`, Linux amd64 | Configuration and native test runtime | MPL-2.0 |
| hashicorp/aws | `6.28.0` | Provider schema, with AWS operations mocked in tests | MPL-2.0 |

## What was inspected and copied

The [pinned implementation](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/b3abd6df2ecf052451a361ed55b8f06f8742a795) and its NAT scenario documentation determine the example's flag settings. Source inspection followed private route-table counts, subnet associations, NAT placement and default-route targets in `main.tf`, then public outputs and the private/intra subnet distinction. The upstream formatting/validation workflow provided a development reference.

All 111 tracked regular files, totaling 934,669 bytes, are copied unchanged into `upstream`. [source-manifest.json](source-manifest.json) records byte hashes, Git blob identities, the commit/tree and modes. Git metadata and provider caches are excluded. Retained upstream workflows are reference files, not evidence that those jobs ran.

The module retains [its Apache-2.0 license](upstream/LICENSE); an additional copy is in [LICENSES](LICENSES/terraform-aws-vpc-Apache-2.0.txt). The example and native tests use the [local MIT license](LICENSE).

## Adaptation

The root fixture maps one `nat_mode` value to the upstream NAT flags. Existing native tests inspect planned counts and actual resource relationships. To execute the included source, the root and three direct-binding test modules use `./upstream`: four source-string changes across two files. Upstream resources and the 33 assertions remain unchanged.

The recorded comparison is original remote-source adapter → byte-identical source copy → locally composed adapter. It is not a claim that the complete upstream test suite ran. See [VERIFICATION.md](VERIFICATION.md) for the original, historical negative check and new local full-suite evidence.

## Research background

Yiming Qiu, Patrick Kon, Ryan Beckett and Ang Chen, [Unearthing Semantic Checks for Cloud Infrastructure-as-Code Programs](https://www.microsoft.com/en-us/research/publication/unearthing-semantic-checks-for-cloud-infrastructure-as-code-programs/), SOSP 2024.

The paper motivates checking semantic requirements beyond compilation, using mined checks and deployment-based testing for Azure resources. These hand-written mocked AWS tests check one module's configuration relationships. They do not reproduce the paper's system, deployment validation or experimental results.
