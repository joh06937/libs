/**
 * @file
 *
 * Contains a boilerplate interface class for creating iterable children classes
 */
#pragma once

#include <cstddef>
#include <utility>

namespace util
{
    template <typename T>
    class Iterable;
}

/// A base interface that provides the duck typing needed to use a child class
/// as an iterable
///
/// That is, this class requests a child class implement an API for getting
/// items and the item capacity of the child class, but otherwise just
/// implements the duck typing APIs that C++'s range-based for loops expect.
/// This class is quite simple, but it's here because who has time to keep
/// writing this duck typing boilerplate over and over for each class
/// individually?
///
/// Note that this class does not care at all about locking access to items with
/// something like a mutex. If that's necessary for the child class (and when
/// isn't it), it must be implemented by the child's getter function.
template <typename T>
class util::Iterable
{
    private:
        /// A helper that's returned by the iterable class as an object that's
        /// used within a range-based for loop
        ///
        /// This class is incremented as part of the range-based for loop's
        /// looping over items, meaning it is the thing that knows how to go
        /// through all of the iterable object's items.
        class Iterator
        {
            private:
                /// The iterable we're iterating over
                Iterable &iterable;

                /// The item in the iterable we're currently at
                size_t index;

            public:
                /**
                 * Creates an iterator
                 *
                 * @param &iterable
                 *      The iterable we'll manage
                 * @param index
                 *      Which item we're pointing at (usually either the start
                 *      or the end)
                 *
                 * @return none
                 */
                constexpr Iterator(Iterable &iterable, size_t index):
                    iterable{iterable},
                    index{index} {}

                /**
                 * Compares us to another iterator
                 *
                 * @param &other
                 *        The iterator to compare to
                 *
                 * @return bool
                 *        Whether or not we equal the other iterator
                 */
                bool operator==(const Iterator &other) const
                {
                    return (this->index == other.index);
                }

                /**
                 * Compares us to another iterator
                 *
                 * @param &other
                 *        The iterator to compare to
                 *
                 * @return bool
                 *        Whether or not we do not equal the other iterator
                 */
                bool operator!=(const Iterator &other) const
                {
                    return !(*this == other);
                }

                /**
                 * Gets a reference to the item in the iterable we're currently
                 * at
                 *
                 * @param none
                 *
                 * @return T &
                 *        The item
                 */
                T &operator*() const
                {
                    return this->iterable[this->index];
                }

                /**
                 * Gets a pointer to the item in the iterable we're currently at
                 *
                 * @param none
                 *
                 * @return T *
                 *        The item
                 */
                T *operator->() const
                {
                    return &this->iterable[this->index];
                }

                /**
                 * Moves the iterator to the next item in the iterable
                 *
                 * @param none
                 *
                 * @return Iterator &
                 *        Us
                 */
                Iterator &operator++()
                {
                    this->index++;

                    return *this;
                }
        };

    protected:
        /**
         * Gets the capacity of the child class
         *
         * @param none
         *
         * @return size_t
         *        The capacity of the child class
         */
        virtual size_t GetSize() const = 0;

        /**
         * Gets an item from the child class
         *
         * @param index
         *        The index of the item to get
         *
         * @return nullptr
         *        No item available at the index
         * @return T *
         *        The item from the index
         */
        virtual T *GetItem(size_t index) = 0;

    public:
        /**
         * Gets the capacity of the iterable
         *
         * @param none
         *
         * @return size_t
         *        The capacity of the iterable
         */
        size_t size() const
        {
            return this->GetSize();
        }

        /**
         * Gets an item
         *
         * Note that this will not perform any kind of check that an item exists
         * at the index! I.e. this will act like getting an item using
         * `operator[]` of `std::array`.
         *
         * @param index
         *        Which item to get
         *
         * @return T &
         *        The item
         */
        T &operator[](size_t index)
        {
            return *this->Get(index);
        }

        /**
         * Gets a starting iterator
         *
         * This object is typically what's used to access items in a range-based
         * for loop: it gets items, it increments, and it compares to what's
         * returned from `end()` below.
         *
         * @param none
         *
         * @return Iterator
         *        The iterator
         */
        Iterator begin()
        {
            return Iterator{*this, 0};
        }

        /**
         * Gets an ending iterator
         *
         * This object is typically left alone and only compared to by what's
         * returned from `begin()` above.
         *
         * @param none
         *
         * @return Iterator
         *        The iterator
         */
        Iterator end()
        {
            return Iterator{*this, std::size(*this)};
        }
};
