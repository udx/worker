const { Octokit } = require("@octokit/rest");
const fs = require("fs");
const path = require("path");

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN,
});

/**
 * This function creates a release on a GitHub repository using the Octokit library.
 * @param {*} changelogFile
 * @returns release.data.id
 */
async function createRelease(changelogFile) {
  const semVer = process.env.semVer;
  const changelog = fs.readFileSync(changelogFile, "utf8");
  const release = await octokit.rest.repos.createRelease({
    owner: process.env.GITHUB_REPOSITORY.split("/")[0],
    repo: process.env.GITHUB_REPOSITORY.split("/")[1],
    tag_name: `v${semVer}`,
    name: `Release v${semVer}`,
    body: `Release Notes:\n${changelog}`,
  });

  return release.data.id;
}

/**
 * This function uploads a release asset to a GitHub repository using the Octokit library.
 * @param {*} releaseId
 * @param {*} assetPath
 * @param {*} assetName
 * @returns
 */
async function uploadReleaseAsset(releaseId, assetPath, assetName) {
  const assetMimeType = "application/gzip";
  const file = fs.readFileSync(
    path.join(__dirname, "../../", assetPath, assetName)
  );

  await octokit.rest.repos.uploadReleaseAsset({
    owner: process.env.GITHUB_REPOSITORY.split("/")[0],
    repo: process.env.GITHUB_REPOSITORY.split("/")[1],
    release_id: releaseId,
    name: assetName,
    data: file,
    headers: {
      "content-type": assetMimeType,
      "content-length": file.length,
    },
  });
}

module.exports = {
  createRelease,
  uploadReleaseAsset,
};
