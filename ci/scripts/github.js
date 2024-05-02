const { Octokit } = require("@octokit/rest");
const fs = require("fs");
const path = require("path");

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN,
});

/**
 *
 * This function creates a release on a GitHub repository using the Octokit library.
 *
 * It retrieves the semantic version number and changelog file path from the environment variables.
 *
 * An instance of Octokit is created with the provided token for authentication.
 *
 * The script calls the createRelease method on the repos object of the Octokit instance.
 * The method is called with an options object that includes the repository owner and name, the tag name,
 * the release name, and the release notes (changelog).
 *
 * The release ID is returned from the method call.
 *
 * @param {*} changelogFile
 *
 * @returns release.data.id
 *
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
 *
 * This function uploads a release asset to a GitHub repository using the Octokit library.
 *
 * It first imports the necessary modules: fs for file system operations, path for file path operations,
 * and Octokit from the @octokit/rest package for interacting with the GitHub API.
 *
 * It then retrieves the GitHub token, release ID, and asset path from the command line arguments.
 *
 * An instance of Octokit is created with the provided token for authentication.
 *
 * The asset name is extracted from the asset path, and the MIME type for the asset is set to "application/gzip".
 *
 * The asset file is read into memory using fs.readFileSync.
 *
 * The script then calls the uploadReleaseAsset method on the repos object of the Octokit instance.
 * The method is called with an options object that includes the repository owner and name, the release ID,
 * the asset name, the asset data, and headers specifying the content type and length.
 *
 * If an error occurs during the upload, it is caught and logged to the console.
 *
 * @param {*} releaseId
 * @param {*} assetPath
 *
 * @returns
 */
async function uploadReleaseAsset(releaseId, assetPath, assetName) {
  // const assetName = path.basename(assetPath);
  const assetMimeType = "application/gzip";
  const file = fs.readFileSync(path.join('../../', assetPath, assetName));

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
