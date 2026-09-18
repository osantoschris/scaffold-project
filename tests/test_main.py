import unittest
from src.main import get_welcome_message


class TestMain(unittest.TestCase):
    def test_welcome_message_contains_app_name(self):
        message = get_welcome_message()
        self.assertIn("{{PROJECT_NAME}}", message)


if __name__ == "__main__":
    unittest.main()
