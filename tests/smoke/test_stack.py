"""通过本地网关检查各服务及抢购实例。运行前先启动 Compose 环境。"""

import json
import os
import unittest
from urllib.error import HTTPError, URLError
from urllib.request import urlopen


class StackSmokeTest(unittest.TestCase):
    base_url = os.environ.get("ZSZQ_BASE_URL", "http://127.0.0.1:8080").rstrip("/")

    def probe(self, service):
        url = f"{self.base_url}/health/{service}"
        try:
            with urlopen(url, timeout=5) as response:
                self.assertEqual(json.load(response)["status"], "UP", service)
                upstream = response.headers.get("X-Upstream-Address", "")
                return upstream.rsplit(",", maxsplit=1)[-1].strip()
        except HTTPError as error:
            raise AssertionError(f"{url} 返回 HTTP {error.code}") from None
        except URLError as error:
            raise AssertionError(f"{url} 就绪检查失败，{error.reason}") from None

    def test_all_services_are_ready(self):
        for service in ("activity", "purchase", "order", "ta"):
            with self.subTest(service=service):
                self.probe(service)

    def test_gateway_reaches_two_purchase_instances(self):
        instances = {self.probe("purchase") for _ in range(10)}
        self.assertNotIn("", instances)
        self.assertGreaterEqual(len(instances), 2, f"抢购上游只有 {instances}")


if __name__ == "__main__":
    unittest.main()
