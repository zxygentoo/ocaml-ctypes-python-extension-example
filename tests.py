import unittest


class TestCases(unittest.TestCase):

    def test_answer(self):

        from pymod import answer

        self.assertEqual(answer(), 42)

    def test_double_int(self):

        from pymod import double_int

        self.assertEqual(double_int(-1), -2)
        self.assertEqual(double_int(0), 0)
        self.assertEqual(double_int(42), 84)


if __name__ == '__main__':

    unittest.main()
