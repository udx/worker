const { Octokit } = require("@octokit/rest");

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN,
});

async function createRelease() {
  const semVer = process.env.semVer;
  const changelog = process.env.changelog;
  const release = await octokit.rest.repos.createRelease({
    owner: process.env.GITHUB_REPOSITORY.split('/')[0],
    repo: process.env.GITHUB_REPOSITORY.split('/')[1],
    tag_name: `v${semVer}`,
    name: `Release v${semVer}`,
    body: `Release Notes:\n${changelog}`,
  });

  console.log(release.data.id);
}

createRelease();