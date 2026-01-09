#!/usr/bin/env python3

import argparse
import json
import shlex
import subprocess
import sys
from typing import Any, Optional, Union

import yaml

_DRY_RUN = False


def _run(
    cmd: Union[str, list[str]], **kwargs: Any
) -> Optional[subprocess.CompletedProcess[str]]:
    """Verbose version of check_output with no returns."""
    if isinstance(cmd, list):
        cmd = [str(element) for element in cmd]
    print(shlex.join(cmd) if isinstance(cmd, list) else cmd)
    sys.stdout.flush()
    if _DRY_RUN and "stdout" not in kwargs:
        return None
    return subprocess.run(cmd, encoding="utf-8", **kwargs)  # nosec


def _use_cluster(name: str, only_use_context: bool) -> None:
    """
    Use the given cluster.
    """
    if not only_use_context:
        print("Use `az login` to be logged in to Azure")
        _run(["kubelogin", "convert-kubeconfig"])
        subscriptions = json.loads(
            _run(["az", "account", "list"], check=True, stdout=subprocess.PIPE).stdout
        )
        subscriptions = [
            s["id"]
            for s in subscriptions
            if s["name"]
            == "[Geospatial Solutions] GS Platform Switzerland (Production)"
        ]
        if len(subscriptions) != 1:
            raise Exception("No subscriptions found for cluster prod")
        _run(["az", "account", "set", f"--subscription={subscriptions[0]}"], check=True)
        _run(
            [
                "az",
                "aks",
                "get-credentials",
                f"--resource-group={name}-rg",
                f"--name={name}",
                f"--context=gs-ch-prod-{name}-aks",
            ],
            check=True,
        )
    _run(["kubectl", "config", "use-context", f"gs-ch-prod-{name}-aks"], check=True)


def _main() -> None:
    """
    Run Kubernetes command with simple ui.
    """

    parser = argparse.ArgumentParser(
        description="Login to Kubernetes",
        usage="""
Connect to blue server:
scripts/login --blue --get-credentials
    """,
    )
    parser.add_argument("--blue", action="store_true", help="Connect to blue cluster")
    parser.add_argument("--green", action="store_true", help="Connect to green cluster")
    parser.add_argument(
        "--dry-run", help="Do not execute the command", action="store_true"
    )
    parser.add_argument(
        "--only-use-context", action="store_true", help="Only use the existing context"
    )
    parser.add_argument(
        "--context", action="store_true", help="The used context details"
    )
    args = parser.parse_args()

    global _DRY_RUN
    _DRY_RUN = args.dry_run

    if args.context:
        _run(["kubectl", "version"])
        print()
        _run(["kubelogin", "--version"])
        print()
        print(
            yaml.dump(
                json.loads(
                    _run(
                        ["az", "account", "show"], check=True, stdout=subprocess.PIPE
                    ).stdout
                )
            )
        )
        context_name = _run(
            ["kubectl", "config", "current-context"], check=True, stdout=subprocess.PIPE
        ).stdout.strip()
        config = yaml.load(
            _run(
                ["kubectl", "config", "view"], check=True, stdout=subprocess.PIPE
            ).stdout,
            Loader=yaml.SafeLoader,
        )
        print()
        context = [c for c in config["contexts"] if c["name"] == context_name][0][
            "context"
        ]
        print("Context:")
        print(yaml.dump(context))
        cluster = [c for c in config["clusters"] if c["name"] == context["cluster"]][0][
            "cluster"
        ]
        print("Cluster:")
        print(yaml.dump(cluster))
        user = [c for c in config["users"] if c["name"] == context["user"]][0]["user"]
        user_config = user.get("auth-provider", {}).get("config", {})
        if "access-token" in user_config:
            user_config["access-token"] = "***"
        if "refresh-token" in user_config:
            user_config["refresh-token"] = "***"
        print("User:")
        print(yaml.dump(user))
    else:
        if args.blue:
            _use_cluster("blue", args.only_use_context)
        elif args.green:
            _use_cluster("green", args.only_use_context)
        else:
            raise Exception("You specify a cluster blue or green")


if __name__ == "__main__":
    _main()
