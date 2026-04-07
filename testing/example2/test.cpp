/**
 * @file
 *
 * Some basic unit tests
 */
#include <gtest/gtest.h>

#include "util/callback.h"

/// Keep everything in our own namespace so we don't conflict with gtest's stuff
namespace test1
{
    class Test;
    static int GetValue(int value);
}

class test1::Test
{
    private:
        int value;

    public:
        constexpr Test(int value):
            value{value} {}

        void SetValue(int value)
        {
            this->value = value;
        }

        int GetValue()
        {
            return this->value;
        }
};

static int test1::GetValue(int value)
{
    return value;
}

/// Runs some tests on callbacks
TEST(UtilTest, Callback)
{
    test1::Test test{5};

    util::Callback<void(int)> setTestValueCallback{util::Bind<&test1::Test::SetValue>(test)};
    util::Callback<int()> getTestValueCallback{util::Bind<&test1::Test::GetValue>(test)};

    // Make sure the values look correct after construction
    EXPECT_EQ(test.GetValue(), 5);
    EXPECT_EQ(getTestValueCallback(), 5);

    // Make sure the values look correct after setting
    setTestValueCallback(8);

    EXPECT_EQ(test.GetValue(), 8);
    EXPECT_EQ(getTestValueCallback(), 8);

    // Make sure the order of the two checks above didn't somehow make the test
    // pass when it shouldn't have
    setTestValueCallback(21);

    EXPECT_EQ(getTestValueCallback(), 21);
    EXPECT_EQ(test.GetValue(), 21);

    // Make sure free function callbacks work (and that we can send an argument
    // and receive a return result from callbacks)
    util::Callback<int(int)> getValueCallback{util::Function(test1::GetValue)};

    EXPECT_EQ(getValueCallback(24), 24);
}
