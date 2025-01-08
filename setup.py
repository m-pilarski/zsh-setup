import os
import pathlib
import shutil
import json
import subprocess
import requests
from datetime import datetime


def backup_config(file_path):
    """
    Back up an existing configuration file by appending a timestamp to its name.
    """
    if file_path.exists():
        backup_dir = file_path.parent / "backup"
        backup_dir.mkdir(exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = backup_dir / f"{file_path.name}.{timestamp}"
        print(f"Backing up {file_path} to {backup_path}")
        shutil.move(str(file_path), str(backup_path))


def copy_config(src, dest):
    """
    Copy a configuration file from the `configs` directory to the destination.
    """
    print(f"Copying {src} to {dest}")
    shutil.copy2(src, dest)


def get_latest_release_or_tag(user, repo):
    """
    Fetch the latest release tag or fallback to the latest tag from GitHub API.
    """
    release_url = f"https://api.github.com/repos/{user}/{repo}/releases"
    tags_url = f"https://api.github.com/repos/{user}/{repo}/tags"

    try:
        response = requests.get(release_url)
        response.raise_for_status()
        data = response.json()
        if data:
            return data[0]["tag_name"]
    except (requests.RequestException, KeyError):
        pass

    try:
        response = requests.get(tags_url)
        response.raise_for_status()
        data = response.json()
        if data:
            return data[0]["name"]
    except (requests.RequestException, KeyError):
        raise RuntimeError(f"Failed to fetch tag information for {user}/{repo}")

    raise RuntimeError(f"No releases or tags found for {user}/{repo}")


def clone_or_update_repo(user, repo, tag, dest_dir):
    """
    Clone the repository at the specified tag or update it if it already exists.
    """
    if dest_dir.exists():
        print(f"Removing existing directory: {dest_dir}")
        shutil.rmtree(dest_dir)

    print(f"Cloning {user}/{repo} at tag {tag} into {dest_dir}")
    subprocess.run(
        [
            "git", "clone",
            f"https://github.com/{user}/{repo}.git",
            f"--branch={tag}",
            "--depth=1",
            str(dest_dir),
        ],
        check=True,
    )


def main():
    # Paths
    home_dir = pathlib.Path.home()
    base_dir = home_dir / ".local" / "share" / "zsh"
    configs_dir = pathlib.Path(__file__).parent / "configs"

    # Load dependencies
    with open(pathlib.Path(__file__).parent / "dependencies.json") as f:
        dependencies = json.load(f)

    # Backup and replace configuration files
    for config_file in configs_dir.iterdir():
        target_path = home_dir / config_file.name
        backup_config(target_path)
        copy_config(config_file, target_path)

    # Install dependencies
    for dep in dependencies:
        dep_class = dep["dep_class"]
        user_name = dep["user_name"]
        repo_name = dep["repo_name"]

        try:
            tag_name = get_latest_release_or_tag(user_name, repo_name)
            dest_dir = base_dir / dep_class / repo_name
            clone_or_update_repo(user_name, repo_name, tag_name, dest_dir)
        except RuntimeError as e:
            print(f"Error: {e}")

    print("Setup complete!")


if __name__ == "__main__":
    main()
