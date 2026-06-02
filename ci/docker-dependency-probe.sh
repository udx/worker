#!/usr/bin/env bash
set -euo pipefail

dockerfile="${DOCKERFILE:-Dockerfile}"
image="${PROBE_IMAGE:-worker-deps-probe:${GITHUB_RUN_ID:-local}}"
report="${PROBE_REPORT:-docker-dependency-report.json}"

usage() {
  cat <<'EOF'
Usage: ci/docker-dependency-probe.sh [--dockerfile Dockerfile] [--image tag] [--report path]

Build a temporary Dockerfile with dependency pins removed, then report the
versions that the image actually installs.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dockerfile)
      dockerfile="$2"
      shift 2
      ;;
    --image)
      image="$2"
      shift 2
      ;;
    --report)
      report="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -f "${dockerfile}" ]; then
  echo "Dockerfile not found: ${dockerfile}" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
probe_dockerfile="${tmpdir}/Dockerfile.unpinned-probe"
trap 'rm -rf "${tmpdir}"' EXIT

base_image="$(awk '$1 == "FROM" { print $2; exit }' "${dockerfile}")"

mapfile -t apt_packages < <(
  awk '
    /apt-get install -y --no-install-recommends/ { in_block=1; next }
    in_block {
      line=$0
      gsub(/\\/, "", line)
      gsub(/^[[:space:]]+/, "", line)
      if (line ~ /^[[:alnum:].+-]+=/) {
        split(line, parts, "=")
        print parts[1]
      }
      if ($0 ~ /&&[[:space:]]*\\?$/) {
        in_block=0
      }
    }
  ' "${dockerfile}"
)

awk '
  /^ARG (AZURE_CLI_VERSION|PIP_VERSION|YQ_VERSION|GCLOUD_VERSION)=/ {
    next
  }

  /^# Install yq/ {
    block = "yq"
    print
    next
  }

  /^# Install Google Cloud SDK/ {
    block = "gcloud"
    gcloud_inserted = 0
    print
    next
  }

  /^# Install AWS CLI/ {
    block = "aws"
    print
    next
  }

  /^#/ && $0 !~ /^# Install/ {
    block = ""
    print
    next
  }

  {
    line = $0

    if (line ~ /apt-get install -y --no-install-recommends/) {
      in_apt = 1
    } else if (in_apt && line ~ /^[[:space:]]+[A-Za-z0-9.+-]+=/) {
      sub(/=[^[:space:]]+/, "", line)
    }

    if (line ~ /pip install .*--upgrade pip==\$\{PIP_VERSION\}/) {
      sub(/==\$\{PIP_VERSION\}/, "", line)
    }

    if (line ~ /pip install .*azure-cli==\$\{AZURE_CLI_VERSION\}/) {
      sub(/==\$\{AZURE_CLI_VERSION\}/, "", line)
    }

    if (block == "yq" && line ~ /github.com\/mikefarah\/yq\/releases\/download/) {
      print "    YQ_VERSION=\"$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name)\" && \\"
      sub(/download\/v\$\{YQ_VERSION\}/, "download/${YQ_VERSION}", line)
    }

    if (block == "gcloud" && gcloud_inserted == 0 && line ~ /^RUN ARCH=\$\(uname -m\) && \\$/) {
      print line
      print "    GCLOUD_VERSION=\"$(curl -fsSL https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json | jq -r .version)\" && \\"
      gcloud_inserted = 1
      next
    }

    print line

    if (in_apt && line ~ /&&[[:space:]]*\\?$/) {
      in_apt = 0
    }
  }
' "${dockerfile}" > "${probe_dockerfile}"

if [ "${PROBE_SKIP_BUILD:-false}" = "true" ]; then
  echo "Skipping probe image build and using existing image: ${image}" >&2
else
  echo "Building dependency probe image: ${image}" >&2
  docker build --pull --no-cache -f "${probe_dockerfile}" -t "${image}" .
fi

echo "Collecting dependency inventory from: ${image}" >&2
docker run -i --rm --entrypoint bash "${image}" -s -- "${base_image}" "${apt_packages[@]}" > "${report}" <<'EOF'
set -euo pipefail

base_image="$1"
shift

apt_json="$(
  dpkg-query -W -f='${binary:Package}\t${Version}\n' "$@" \
    | jq -R -s '
        split("\n")
        | map(select(length > 0))
        | map(split("\t") | {name: .[0], installed: .[1]})
      '
)"

os_pretty="$(. /etc/os-release && printf '%s' "${PRETTY_NAME}")"
pip_version="$(/opt/az/bin/pip --version | awk '{ print $2 }')"
azure_cli_version="$(/opt/az/bin/pip show azure-cli | awk -F': ' '$1 == "Version" { print $2 }')"
yq_version="$(yq --version | awk '{ print $NF }' | sed 's/^v//')"
gcloud_version="$(gcloud version --format=json | jq -r '."Google Cloud SDK"')"
aws_cli_version="$(aws --version 2>&1 | awk '{ print $1 }' | sed 's#aws-cli/##')"

jq -n \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg base_image "${base_image}" \
  --arg os "${os_pretty}" \
  --arg arch "$(uname -m)" \
  --arg pip "${pip_version}" \
  --arg azure_cli "${azure_cli_version}" \
  --arg yq "${yq_version}" \
  --arg gcloud "${gcloud_version}" \
  --arg aws_cli "${aws_cli_version}" \
  --argjson apt "${apt_json}" \
  '{
    generated_at: $generated_at,
    method: "unpinned Dockerfile probe build",
    base_image: $base_image,
    runtime: {
      os: $os,
      architecture: $arch
    },
    dependencies: {
      apt: $apt,
      pip: [
        {name: "pip", installed: $pip},
        {name: "azure-cli", installed: $azure_cli}
      ],
      github_releases: [
        {name: "yq", installed: $yq, source: "mikefarah/yq"}
      ],
      archives: [
        {name: "google-cloud-sdk", installed: $gcloud, source: "Google Cloud SDK rapid channel"},
        {name: "aws-cli", installed: $aws_cli, source: "awscli.amazonaws.com latest zip", pinned_in_dockerfile: false}
      ]
    }
  }'
EOF

echo "Dependency report written to ${report}" >&2
