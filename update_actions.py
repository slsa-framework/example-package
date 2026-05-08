import urllib.request
import json
import glob
import re

def get_latest_commit_sha_and_tag(repo):
    try:
        url = f"https://api.github.com/repos/{repo}/releases/latest"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        tag = None
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            tag = data.get('tag_name')

        if tag:
            # get commit sha
            url = f"https://api.github.com/repos/{repo}/git/ref/tags/{tag}"
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode())
                sha = data['object']['sha']
                # Sometimes the tag is an annotated tag, so the sha is the tag object, not the commit.
                if data['object']['type'] == 'tag':
                    url = data['object']['url']
                    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req) as response:
                        tag_data = json.loads(response.read().decode())
                        sha = tag_data['object']['sha']

                return sha, tag
    except Exception as e:
        pass

    return None, None

def main():
    repos = [
        "actions/checkout",
        "actions/download-artifact",
        "actions/setup-go",
        "actions/setup-node",
        "actions/upload-artifact",
        "bazelbuild/setup-bazelisk",
        "docker/build-push-action",
        "docker/login-action",
        "docker/metadata-action",
        "docker/setup-buildx-action",
        "golangci/golangci-lint-action",
        "google-github-actions/auth",
        "google-github-actions/setup-gcloud",
        "goreleaser/goreleaser-action",
        "sigstore/cosign-installer"
    ]

    updates = {}
    for repo in repos:
        sha, tag = get_latest_commit_sha_and_tag(repo)
        if sha and tag:
            updates[repo] = (sha, tag)
            print(f"{repo}: {sha} # {tag}")

    # Now replace in files
    files = []
    for ext in ('*.yml', '*.yaml'):
        files.extend(glob.glob(f'.github/workflows/{ext}'))
        files.extend(glob.glob(f'e2e/*/{ext}'))
        files.extend(glob.glob(f'e2e/{ext}'))

    for filepath in files:
        with open(filepath, 'r') as f:
            content = f.read()

        new_content = content
        for repo, (sha, tag) in updates.items():
            # Match uses: repo@<anything>
            # and replace with uses: repo@sha # tag
            # We need to be careful with quotes and existing comments

            # Simple approach: regex
            pattern = r'uses:\s*["\']?' + re.escape(repo) + r'@[a-zA-Z0-9\._\-]+["\']?(?:\s*#\s*[a-zA-Z0-9\._\-]+)?'
            replacement = f'uses: {repo}@{sha} # {tag}'
            new_content = re.sub(pattern, replacement, new_content)

        if new_content != content:
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f"Updated {filepath}")

if __name__ == "__main__":
    main()
