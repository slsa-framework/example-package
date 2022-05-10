const core = require('@actions/core');
const github = require('@actions/github');
const artifact = require('@actions/artifact');
const varToString = varObj => Object.keys(varObj)[0]

// https://github.com/actions/toolkit
async function main() {
  try {
    // `who-to-greet` input defined in action metadata file
    const nameToGreet = core.getInput('who-to-greet');
    console.log(`Hello ${nameToGreet}!`);
    const time = (new Date()).toTimeString();
    core.setOutput("time", time);
    // Get the JSON webhook payload for the event that triggered the workflow
    const payload = JSON.stringify(github.context.payload, undefined, 2)
    console.log(`The event payload: ${payload}`);

    artifactName = get_variable(process.env.ARTIFACT, "ARTIFACT")
    after = get_variable(process.env.AFTER, "AFTER")
    duration = get_variable(process.env.FOR, "FOR")
    every = get_variable(process.env.EVERY, "EVERY")


    // Wait for after seconds.
    await sleep(after);

    // Loop for duration.
    var startTime = Date.now();
    while ((Date.now() - startTime) < (duration*1000)) {
      console.log(`${Date.now()}`)
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
/*async function uploadArtifact(filename) {
  const artifactClient = artifact.create()
  const artifactName = filename;
  const files = [filename]

  const rootDirectory = '.' // Also possible to use __dirname
  const options = {
    continueOnError: false
  }

  const uploadResponse = await artifactClient.uploadArtifact(artifactName, files, rootDirectory, options)
  console.log(uploadResponse);
}*/

main()