const fs = require("fs");
const path = require("path");
const { Octokit } = require("@octokit/rest");

const [token, releaseId, assetPath] = process.argv.slice(2);
const octokit = new Octokit({ auth: token });

const assetName = path.basename(assetPath);
const assetMimeType = "application/gzip";
const file = fs.readFileSync(assetPath);

octokit.rest.repos
  .uploadReleaseAsset({
    owner: "your-owner",
    repo: "your-repo",
    release_id: releaseId,
    name: assetName,
    data: file,
    headers: {
      "content-type": assetMimeType,
      "content-length": file.length,
    },
  })
  .catch(console.error);
