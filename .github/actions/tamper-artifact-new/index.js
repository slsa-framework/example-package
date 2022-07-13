const core = require('@actions/core');
const github = require('@actions/github');
const artifact = require('@actions/artifact');
const { Octokit } = require("@octokit/action");
const fs = require('fs');
const varToString = varObj => Object.keys(varObj)[0]
const octokit = new Octokit();

// https://github.com/actions/toolkit
// https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action
// Use ncc https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action#commit-tag-and-push-your-action-to-github
async function main() {
  try {
    // get_variable(process.env.ARTIFACT, "ARTIFACT")
    artifactName = core.getInput("artifact-name")
    const artifactPrefix = core.getInput("artifact-prefix")
    const after = core.getInput("after")
    const duration = core.getInput("duration")
    const every = core.getInput("every")
    const [owner, repo] = core.getInput("GITHUB_REPOSITORY").split("/");
    const now = new Date().toUTCString()
    
    // Wait for after seconds.
    await sleep(after);

    // Loop for duration.
    var startTime = Date.now();
    artifactedCreated = false
    while ((Date.now() - startTime) < (duration*1000)) {
      
      await sleep(every);

      console.log(`${Date.now()}`)

      if (artifactName == undefined || artifactName == ""){
        // Resolve the artifact name.
        if (artifactPrefix == undefined || artifactPrefix == ""){
          throw new Error(`${artifactPrefix} is not set`);
        }

        resolveArtifactName(owner, repo, artifactPrefix).then(name => {
          artifactName = name
        }).catch(err => {
            console.log(err);
        });
      }
      
      // Check if the name was successfully resolved.
      if (artifactName == undefined || artifactName == ""){
        console.log("no artifact name resolved");
        continue
      }
      
      // Create the file if not already created.
      if (!artifactCreated){
        // Create file.
        fs.writeFile(artifactName, `some content with date ${now}`, function (err) {
          if (err) throw err;
          console.log('File is created successfully.');
        });
        artifactCreated = true
      }

      // Upload the artifact.
      await uploadArtifact(artifactName)
    }

    console.log("Exiting")

  } catch (error) {
    core.setFailed(error.message);
  }
}

async function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms*1000);
  });
}

async function resolveArtifactName(owner, repo, prefix) {
  // List artifacts.
  listArtifacts(owner, repo).then(artifacts => {
    console.log(`artifacts: ${artifacts}`);

    if (artifacts == undefined) {
      return undefined
    }

    // If an artifact is found, record its name.
    for (let element of artifacts) {
      console.log(`element: ${element}`);
      
      // Artifact name is of the type `name-randomhex`,
      // e.g., slsa-builder-go-linux-amd64-574b40002571aa669e9a8e065c11b421
      if (element.name.startsWith(prefix)) {
        return element.name
      }
    }
  }).catch(err => {
      console.log(err);
  });
}

function getVariable(variable, name) {
  if (undefined === variable) {
    throw new Error(`${name} is undefined`);
  }

  if ("" === variable) {
    throw new Error(`${name} is empty`);
  }

  return variable
}

// https://github.com/actions/toolkit/tree/main/packages/artifact
// Note: we could also do it entirely in the workflows, as in https://github.com/actions/toolkit/blob/37f5a852195044ba36b22b05242b57bd41e84370/.github/workflows/artifact-tests.yml
async function uploadArtifact(filename) {
  const artifactClient = artifact.create()
  const artifactName = filename;
  const files = [filename]

  const rootDirectory = '.' // Also possible to use __dirname
  const options = {
    continueOnError: false
  }

  return artifactClient.uploadArtifact(artifactName, files, rootDirectory, options)
}

async function listArtifacts(owner, repo) {

  try {
    const runid = getVariable(process.env.ARTIFACT, "RUN_ID")
    console.log(`runid: {runid}`);
    
    // See https://docs.github.com/en/rest/reference/actions#artifacts
    const { data } = await octokit.request(
      "GET /repos/{owner}/{repo}/actions/runs/{runid}/artifacts",
      {
        owner,
        repo,
      }
    );
    return data.artifacts;

  } catch (error) {
    core.setFailed(error);
  }
}

main()