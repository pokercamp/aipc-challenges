# AI Poker Camp Challenges (S24 Beta)

## Dependencies (python)
 - python>=3.5
 - cython (pip install cython)
 - eval7 (pip install eval7)

## Install

```
git clone --recurse-submodules git@github.com:pokercamp/engine.git
```

or if you have mistakenly done a plain `git clone`:

```
git clone git@github.com:pokercamp/engine.git
git submodule update --init --recursive
```

## Repo structure

aipc-challenges will have a number of different games built on a common game engine; the core game engine is developed at pokercamp/engine. The core game engine is included as a [git submodule](https://www.atlassian.com/git/tutorials/git-submodule) for each separate game. In effect, each folder named challenge-\* is a working directory on a separate branch of the pokercamp/engine repo. Each should already be put on its own branch, for example using:

```
cd challenge-1
git checkout -b S24-challenge-1
```

The top-level repo contains a pointer to a certain repo and commit for each submodule (that is, each different challenge / game).

The primary reason for this is because we may wish to push changes to the core engine (to all games), changes to a particular game (to all students), or you may wish to push your own changes.

## Recommended git process

We recommend you do the following in order to share your changes with others or with us (which you'll need to, in order to submit):

1. On GitHub:

  a. Fork pokercamp/aipc-challenges to [username]/aipc-challenges
  
  b. If you created the repo fork as private, add GitHub users `rossry` and `chisness` as collaborators with at least read permissions.

  c. Fork pokercamp/engine to [username]/pokercamp-engine. **Note: You will only do this once, _not_ once for each challenge.**
  
  d. If you created the repo fork as private, add GitHub users `rossry` and `chisness` as collaborators with at least read permissions.

2. Clone the fork to your local machine and run `init.sh`:

```
export GITHUB_USERNAME=yourname
git clone "git@github.com:$GITHUB_USERNAME/aipc-challenges.git"
cd aipc-challenges.git
echo "$GITHUB_USERNAME" | ./init.sh
```

This should set things up such that when you work on Challenge 1 in the `/challenge-1/` directory, you are working on a personal branch `S24-challenge-1-[username]` that exists only in your `[username]/pokercamp-engine` repo, and that branch is based on our per-project branch `S24-challenge-1`, which exists in `pokercamp/engine`. In turn, the per-project branches are based on the `main` branch in `pokercamp/engine`.

3. When you make changes to a submodule directory (like `/challenge-1/`):

  a. Commit them within the submodule directory, then push. This will go to the branch `S24-challenge-[N]-[username]`` in your repo `[username]/pokercamp-engine`. The `init.sh` script should have already set this up as the default of `git push`.
  
  b. At the top level of the `pokercamp-engine` repo, add the changes (which should appear as `modified file: challenge-1`), commit, and push. This will go to the `S24-[username]` branch (or whatever other branch you've switched to) in your repo `[username]/aipc-challenges`.

## Building and running bots

See [Building and Running Bots](https://poker.camp/aipcs24/bots.html) on the main course site.

## Submitting your bots

Each `challenge-[N]` submodule should already have a symlink `submit` that goes to `players/default/`. We recommend adding your submission as a directory under `players/` and pointing `submit` to it. You can do this with:

```
export BOT_TO_SUBMIT="yourbot"
ln -sf players/$BOT_TO_SUBMIT submit
```

(It will probably be work if you put a directory called `submit` there instead of a symlink, but that just seems less convenient for you.)

### On our end

On our end, we will periodically pull changes to the top-level repo, update the submodules if the top-level repo moves them forward to new commits, and look for a `submit/` link (or directory). If we find one, and it has a `commands.json`, then in each matchup we'll call the `build` command, then the `run` command. If you haven't modified `commands.json`, then `build` will do nothing and `run` will call `python3 player.py`. If you haven't changed the boilerplate of `player.py` and `skeleton/runner.py`, this should start up your bot and begin calling `handle_new_round()`, `handle_round_over()`, and the `get_action()` functions as the bot plays its matchup.

If the version of your repo that we pull does not have a submodule folder for that challenge, or if the version of the submodule that we update to doesn't have a `submit` symlink or directory, or if that directory doesn't have a `commands.json`, then we'll drop you from that tournament run.
