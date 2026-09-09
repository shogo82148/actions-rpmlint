import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).parents[1] / "post-pr-comment.py"
SPEC = importlib.util.spec_from_file_location("post_pr_comment", SCRIPT)
post_pr_comment = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(post_pr_comment)


class PostPullRequestCommentTest(unittest.TestCase):
    def test_posts_rpmlint_output_to_pull_request(self):
        with tempfile.TemporaryDirectory() as directory:
            event = Path(directory) / "event.json"
            output = Path(directory) / "output.txt"
            event.write_text(json.dumps({"pull_request": {"number": 42}}))
            output.write_text("bad.spec:1: an error\n")
            captured = {}

            class Response:
                def __enter__(self):
                    return self

                def __exit__(self, *args):
                    pass

            def urlopen(request, timeout):
                captured["url"] = request.full_url
                captured["authorization"] = request.get_header("Authorization")
                captured["api_version"] = dict(
                    (name.lower(), value) for name, value in request.header_items()
                )["x-github-api-version"]
                captured["body"] = json.loads(request.data)["body"]
                captured["timeout"] = timeout
                return Response()

            environment = {
                "INPUT_GITHUB_TOKEN": "secret",
                "GITHUB_REPOSITORY": "owner/repo",
                "GITHUB_EVENT_PATH": str(event),
                "GITHUB_API_URL": "https://github.example/api/v3",
            }
            with (
                patch.dict(os.environ, environment, clear=True),
                patch.object(post_pr_comment.urllib.request, "urlopen", urlopen),
                patch.object(
                    post_pr_comment.sys,
                    "argv",
                    ["post-pr-comment.py", str(output)],
                ),
            ):
                self.assertEqual(post_pr_comment.main(), 0)

            self.assertEqual(
                captured["url"],
                "https://github.example/api/v3/repos/owner/repo/issues/42/comments",
            )
            self.assertEqual(captured["authorization"], "Bearer secret")
            self.assertEqual(captured["api_version"], "2026-03-10")
            self.assertIn("bad.spec:1: an error", captured["body"])
            self.assertEqual(captured["timeout"], 30)

    def test_skips_non_pull_request_event(self):
        with tempfile.TemporaryDirectory() as directory:
            event = Path(directory) / "event.json"
            output = Path(directory) / "output.txt"
            event.write_text("{}")
            output.write_text("failure")

            environment = {"GITHUB_EVENT_PATH": str(event)}
            with (
                patch.dict(os.environ, environment, clear=True),
                patch.object(
                    post_pr_comment.sys,
                    "argv",
                    ["post-pr-comment.py", str(output)],
                ),
            ):
                self.assertEqual(post_pr_comment.main(), 0)


if __name__ == "__main__":
    unittest.main()
