/**
 * @file
 *
 * A wrapper for a global variable
 */
#pragma once

#include <cstddef>

namespace util
{
	template <typename T>
	class Singleton;
}

/// A helper for marginally better global variable design
///
/// This class allows for global resources, but allows for the singleton to not
/// be set yet. That is, this replaces the global initialization problem with
/// C++ global variables with a more explicit interface, allowing for things to
/// know for sure that the resource isn't available yet; and for the global
/// variable to be constructed in a more reliable fashion that globally. For
/// instance, the global variable can be declared and constructed in `main()`
/// and plugged into the singleton object at run time, allowing for the global
/// variable to be shared across the program while avoiding it being
/// accidentally used before it's constructed or initialized.
///
/// These singleton object can be classic global variables that are used
/// directly by the application, but it's recommended to use the singleton
/// getter API included in the `util` namespace below. This will likely not have
/// a big impact on an application, but adhering to that approach can better
/// allow for function-scope variable (and thus lazy loading) use.
template <typename T>
class util::Singleton
{
	private:
		/// The object we're wrapping
		T* instance = nullptr;

	public:
	    /// Singletons will usually be default-constructed
		constexpr Singleton() = default;

		/**
		 * Creates a singleton
		 *
		 * @param instance
		 *		The object to wrap
		 *
		 * @return none
		 */
		constexpr Singleton(T& instance):
			instance{&instance} {}

		/**
		 * Sets the singleton's instance
		 *
		 * @param instance
		 *		The instance to set
		 *
		 * @return none
		 */
		Singleton& operator=(T& instance)
		{
			this->instance = &instance;

			return *this;
		}

		/**
		 * Sets the singleton's instance
		 *
		 * Note that this variant allows for clearing the instance (i.e. setting
		 * it to `nullptr`).
		 *
		 * @param instance
		 *		The instance to set
		 *
		 * @return none
		 */
		Singleton& operator=(T* instance)
		{
			this->instance = instance;

			return *this;
		}

		/**
		 * Gets if the singleton's instance is set
		 *
		 * @param none
		 *
		 * @return bool
		 *		Whether or not the singleton's instance is set
		 */
		explicit operator bool() const
		{
			return (this->instance != nullptr);
		}

		/**
		 * Gets the singleton's instance, if set
		 *
		 * @param none
		 *
		 * @return nullptr
		 *      Instance not set
		 * @return T*
		 *		The singleton's instance
		 */
		T* operator*() const
		{
			return this->instance;
		}
};

namespace util
{
    /**
     * Gets a singleton of a given type
     *
     * @tparam
     *      The type of object wrapped by the singleton
     *
     * @param none
     *
     * @return Singleton<T>&
     *      The singleton
     */
    template <typename T>
    extern Singleton<T>& GetSingleton<T>();

    /**
     * Gets one of the singletons of a given type
     *
     * @tparam
     *      The type of object wrapped by the singleton
     *
     * Note that this variable provides the ability for more than one singleton
     * of a given type to exist on the system (for example, serial ports). This
     * also means that users could request singletons that don't exist, and thus
     * must check the return value for `nullptr`.
     *
     * @param index
     *      Which of the singleton instances to get
     *
     * @return nullptr
     *      Singleton not available
     * @return Singleton<T>*
     *      The singleton
     */
    template <typename T>
    extern Singleton<T>* GetSingleton<T>(size_t index);
}
