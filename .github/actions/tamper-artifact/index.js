const core = require('@actions/core');
const github = require('@actions/github');

// https://github.com/actions/toolkit
try {
  // `who-to-greet` input defined in action metadata file
  const nameToGreet = core.getInput('who-to-greet');
  console.log(`Hello ${nameToGreet}!`);
  const time = (new Date()).toTimeString();
  core.setOutput("time", time);
  // Get the JSON webhook payload for the event that triggered the workflow
  const payload = JSON.stringify(github.context.payload, undefined, 2)
  console.log(`The event payload: ${payload}`);
} catch (error) {
  core.setFailed(error.message);
}

/*
// Assuming the current working directory is /home/user/files/plz-upload
const artifact = require('@actions/artifact');
const artifactClient = artifact.create()
const artifactName = 'my-artifact';
const files = [
    'file1.txt',
    'file2.txt',
    'dir/file3.txt'
]

const rootDirectory = '.' // Also possible to use __dirname
const options = {
    continueOnError: false
}

const uploadResponse = await artifactClient.uploadArtifact(artifactName, files, rootDirectory, options)
*/