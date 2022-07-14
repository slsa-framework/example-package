const core = require('@actions/core');
const github = require('@actions/github');
const artifact = require('@actions/artifact');
const {HttpClient} = require("@actions/http-client");
//const {BearerCredentialHandler} = require("@actions/http-client/auth");
const { Octokit } = require("@octokit/action");
const octokit = new Octokit();

const fs = require('fs');
const varToString = varObj => Object.keys(varObj)[0]
//const [owner, repo] = process.env.GITHUB_REPOSITORY.split("/")

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
    
    const now = new Date().toUTCString()
    
    // Wait for after seconds.
    console.log(`Waiting for ${after}s`)
    await sleep(after);

    // Loop for duration.
    var startTime = Date.now();
    filesToUpload = []
    while ((Date.now() - startTime) < (duration*1000)) {
      
      await sleep(every);

      console.log(`${Date.now()}`)

      if (artifactName == undefined || artifactName == ""){
        // Resolve the artifact name.
        if (artifactPrefix == undefined || artifactPrefix == ""){
          throw new Error(`${artifactPrefix} is not set`);
        }

        artifactName = await resolveArtifactName(artifactPrefix)
        console.log(`resolved name: ${artifactName}`)

        // Check if the name was successfully resolved.
        if (artifactName == undefined || artifactName == ""){
          console.log("no artifact name resolved");
          continue
        }
      }
      
      
      // Create the file if not already created.
      if (filesToUpload.length == 0){
        // Create 2 files: we do this because the generator sometimes
        // upload a file that has a different path than the artifact name itself.
        fs.writeFile(artifactName, `some content with date ${now}`, function (err) {
          if (err) throw err;
          console.log(`File ${artifactName} is created successfully.`)
          filesToUpload.push(artifactName)
        });

        if (artifactPrefix != undefined && artifactPrefix != "") {
          fs.writeFile(artifactPrefix, `some content with date ${now}`, function (err) {
            if (err) throw err;
            console.log(`File ${artifactPrefix} is created successfully.`)
          });
          filesToUpload.push(artifactPrefix)
        }
      }

      // Upload the artifacts.
      // The generator always sets the name of the artifact to the random name, 
      // which is artifactName.
      await uploadArtifacts(artifactName, filesToUpload)
    }

    console.log("Exiting")

  } catch (error) {
    core.setFailed(error.message);
  }
}

class BearerCredentialHandler {
  constructor(token) {
      this.token = token;
  }
  // currently implements pre-authorization
  // TODO: support preAuth = false where it hooks on 401
  prepareRequest(options) {
      options.headers['Authorization'] = 'Bearer ' + this.token;
  }
  // This handler cannot handle 401
  canHandleAuthentication(response) {
      return false;
  }
  handleAuthentication(httpClient, requestInfo, objs) {
      return null;
  }
}

async function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms*1000);
  });
}

async function resolveArtifactName(prefix) {
  // List artifacts.
  artifacts = await listArtifacts()

  console.log(`artifacts: ${artifacts}`)

  if (artifacts == undefined) {
    return undefined
  }

  // If an artifact is found, record its name.
  for (let element of artifacts) {
    console.log(`element: ${element}, ${element.name}`);
    let myString = JSON.stringify(element, null, 4);
    console.log(`asJSON: ${myString}`);
    console.log(`prefix: ${prefix}`);
    console.log(element.name.startsWith(prefix));
    // Artifact name is of the type `name-randomhex`,
    // e.g., slsa-builder-go-linux-amd64-574b40002571aa669e9a8e065c11b421
    if (element.name.startsWith(prefix + "-")) {
      console.log(`returning: ${element.name}`);
      return element.name
    }
  }

  return undefined
}

function validateVariable(variable) {
  if (undefined === variable) {
    throw new Error(`${variable} is undefined`);
  }

  if ("" === variable) {
    throw new Error(`${variable} is empty`);
  }

  return variable
}

// https://github.com/actions/toolkit/tree/main/packages/artifact
// Note: we could also do it entirely in the workflows, as in https://github.com/actions/toolkit/blob/37f5a852195044ba36b22b05242b57bd41e84370/.github/workflows/artifact-tests.yml
async function uploadArtifacts(artifactName, files) {
  const artifactClient = artifact.create()

  const rootDirectory = '.' // Also possible to use __dirname
  const options = {
    continueOnError: false
  }

  return artifactClient.uploadArtifact(artifactName, files, rootDirectory, options)
}

// Code from https://github.com/mozilla/DeepSpeech/blob/a6bdf0ae3c190cbaf39dc4598cc87a55047e38fa/.github/actions/update-cache-index/main.js#L8-L37
// as suggested workaround in https://github.com/actions/upload-artifact/issues/53. 
function createHttpClient(userAgent) {
  return new HttpClient(userAgent, [
    // From https://github.com/actions/toolkit/blob/main/packages/artifact/src/internal/config-variables.ts
    new BearerCredentialHandler(process.env.ACTIONS_RUNTIME_TOKEN)
  ]);
}

async function listArtifacts() {
    // From https://github.com/actions/toolkit/blob/main/packages/artifact/src/internal/config-variables.ts
    const runtimeUrl = process.env.ACTIONS_RUNTIME_URL;
    const runId = process.env.GITHUB_RUN_ID;
    // From https://github.com/actions/toolkit/blob/main/packages/artifact/src/internal/utils.ts
    const apiVersion = "6.0-preview";
    let url = `${runtimeUrl}_apis/pipelines/workflows/${runId}/artifacts?api-version=${apiVersion}`

    const client = createHttpClient("@actions/artifact-download");
    const response = await client.get(url, {
        "Content-Type": "application/json",
        "Accept": `application/json;api-version=${apiVersion}`,
    });

    const allArtifacts = JSON.parse(await response.readBody()).value;
    console.log(`==> Got ${allArtifacts.length} artifacts in response`);
    return allArtifacts;
}


/* 
  WARNING: the API below does not work unless the run is complete.
  See https://github.com/actions/upload-artifact/issues/53.

async function listArtifacts(owner, repo) {

  try {
    const runid = process.env.GITHUB_RUN_ID
    console.log(`runid: ${runid}`);
    console.log(`owner: ${owner}`);
    console.log(`repo: ${repo}`);
    
    // See https://docs.github.com/en/rest/reference/actions#artifacts
    const { data } = await octokit.request(
      "GET /repos/{owner}/{repo}/actions/runs/{runid}/artifacts",
      {
        owner, repo, runid
      }
    );
    let myString = JSON.stringify(data, null, 4);
    console.log(`data: ${myString}`);
    return data.artifacts;

  } catch (error) {
    core.setFailed(error);
  }
}
*/

main()