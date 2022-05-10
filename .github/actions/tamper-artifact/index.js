const core = require('@actions/core');
const github = require('@actions/github');
const artifact = require('@actions/artifact');
const fs = require('fs');
const varToString = varObj => Object.keys(varObj)[0]

// https://github.com/actions/toolkit
// https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action
// Use ncc https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action#commit-tag-and-push-your-action-to-github
async function main() {
  try {
    const artifactName = get_variable(process.env.ARTIFACT, "ARTIFACT")
    const after = get_variable(process.env.AFTER, "AFTER")
    const duration = get_variable(process.env.FOR, "FOR")
    const every = get_variable(process.env.EVERY, "EVERY")
    const now = new Date().toUTCString()
    
    // Create file.
    fs.writeFile(artifactName, `some content with date ${now}`, function (err) {
      if (err) throw err;
      console.log('File is created successfully.');
    });

    // Wait for after seconds.
    await sleep(after);

    // Loop for duration.
    var startTime = Date.now();
    while ((Date.now() - startTime) < (duration*1000)) {
      console.log(`${Date.now()}`)
      await uploadArtifact(artifactName)
      await sleep(every);
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

function get_variable(variable, name) {
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

main()