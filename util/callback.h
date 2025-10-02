/**
 * @file
 *
 * Contains the callback utility, which is more or less std::function, just a
 * bit more barebones and with a guarantee of no heap usage
 */
#pragma once

#include <type_traits>

namespace util
{
	template <typename R, typename... Args>
	class Callback;
}

/// This class is more or less std::function, but with fewer bells and whistles
/// (that I don't tend to need, and thus haven't written) and with a guarantee
/// of no dynamic memory allocation (i.e. heap usage). Most uses of this class
/// should be to store a util::Callback object as it's returned from one of the
/// helper APIs below, util::Function() and util::Bind(). It's not recommended
/// to instantiate a util::Callback object by hand.
///
/// More details about how these two use cases are achieved can be found in the
/// various function documentation below.
///
/// Example usage:
///
/// @code{.cpp}
///	class Talker
///	{
///		private:
///			util::Callback<bool(int)> listener;
///
///			void Talk()
///			{
///				// Some demo value to pass to our listener
///				int arg = 1234;
///
///				// If the callback isn't set, log that
///				if (!this->listener.IsSet())
///				{
///					std::cout << "Callback not set\n";
///				}
///
///				// Try to invoke the callback
///				//
///				// The invocation will automatically check if it's set before
///				// attempting to dereference the function pointer, so don't
///				// bother checking. The above was just to demonstrate that you
///				// can if it's meaningful to your application. However, do note
///				// that the return value will be default-constructed if the
///				// callback isn't set.
///				bool result = this->listener(arg);
///
///				std::cout << "Got result '" << result << "'\n";
///			}
///
///		public:
///			void Subscribe(util::Callback<bool(int)> && listener)
///			{
///				// Callbacks can be simply written over, so just reassign the
///				// value of our saved listener callback
///				this->listener = listener;
///			}
///
///			void Run()
///			{
///				this->Talk();
///			}
///	};
///
///	class Listener
///	{
///		private:
///			bool Handler(int arg)
///			{
///				// Print the value we're being invoked with
///				std::cout << "Got called with '" << arg << "'\n";
///
///				// Return a result from our handling of this callback
///				if (foo)
///				{
///					return true;
///				}
///
///				return false;
///			}
///
///		public:
///			Listener(Talker &talker)
///			{
///				// Subscribe to talks from our talker using the util::Bind()
///				// helper, which connects class member functions to their object
///				// instance in a callback
///				talker.Subscribe(util::Bind<&Listener::Handler>(*this));
///			}
///	};
///
///	void Bar()
///	{
///		Talker talker;
///		Listener listener(talker);
///		talker.Run();
///	}
/// @endcode
///
/// @code{.cpp}
///	static int Handler(bool arg)
///	{
///		std::cout << "Handler() called with '" << arg << "'\n";
///
///		return 4321;
///	}
///
///	static void Do(util::Callback<int(bool)> && callback)
///	{
///		bool arg = true;
///
///		int result = callback(arg);
///
///		std::cout << "Got result '" << result << "'\n";
///	}
///
///	void main(void)
///	{
///		// Capture the free function in a new callback and have that be used
///		// to do things
///		Do(util::Function(Handler));
///	}
/// @endcode
template <typename R, typename... Args>
class util::Callback<R(Args...)>
{
	public:
		/// The 'context' of a callback
		///
		/// This is usually either a function pointer, such as when using the
		/// util::Function() helper, or a pointer to an object, such as when
		/// using the util::Bind() helper. In either case, the functor just
		/// below will point to an on-the-fly lambda function that knows how to
		/// interpret this pointer and use it appropriately.
		///
		/// This could also be set manually by someone instantiating this class
		/// by hand, but that's not a suggested use case.
		using Context = void *;

		/// The function pointer to invoke with our context when the callback is
		/// invoked
		///
		/// As above, this is typically a lambda function -- for both
		/// util::Function() and util::Bind() -- that will either invoke the
		/// function pointer stored in the context (the former helper) or invoke
		/// an object member function with the object 'this' pointer stored in
		/// the context (the latter helper).
		///
		/// But, like the context, this could also be set manually by a user of
		/// this class.
		typedef R (*Functor)(Context, Args...);

		/// The return value's type
		using ReturnType = R;

	private:
		/// The context our functor is called with
		Context context = nullptr;

		/// Our functor
		Functor functor = nullptr;

	public:
		/**
		 * Creates a callback
		 *
		 * @param context
		 *		Our context
		 * @param functor
		 *		Our functor
		 *
		 * @return none
		 */
		constexpr Callback(Context context, Functor functor):
			context{context},
			functor{functor} {}

		/**
		 * Creates a callback with no context
		 *
		 * @param functor
		 *		Our functor
		 *
		 * @return none
		 */
		constexpr Callback(Functor functor):
			Callback{
				nullptr,
				functor
			} {}

		constexpr Callback() = default;
		constexpr Callback(const Callback &other) = default;
		Callback &operator=(const Callback &other) = default;

		/**
		 * Gets if the callback is set
		 *
		 * @param none
		 *
		 * @return bool
		 *		Whether or not the callback is set
		 */
		constexpr bool IsSet() const
		{
			return (this->functor != nullptr);
		}

		/**
		 * Gets if the callback is set
		 *
		 * @param none
		 *
		 * @return bool
		 *		Whether or not the callback is set
		 */
		explicit constexpr operator bool() const
		{
			return this->IsSet();
		}

		/**
		 * Checks if we equal another callback
		 *
		 * @param &other
		 *		The callback to compare to
		 *
		 * @return bool
		 *		Whether or not we equal the other callback
		 */
		constexpr bool operator==(const Callback &other) const
		{
			return (this->context == other.context) && (this->functor == other.functor);
		}

		/**
		 * Checks if we do not equal another callback
		 *
		 * @param &other
		 *		The callback to compare to
		 *
		 * @return bool
		 *		Whether or not we don't equal the other callback
		 */
		constexpr bool operator!=(const Callback &other) const
		{
			return !(*this == other);
		}

		/**
		 * Invokes the callback
		 *
		 * @tparam ...Argsp
		 *		The types of the arguments for the callback
		 *
		 * @param &&...args
		 *		The arguments to invoke the callback with
		 *
		 * @return R
		 *		The result of the callback
		 */
		template <typename... Argsp>
		constexpr R operator()(Argsp&&... args) const
		{
			// If the callback isn't set, try to return the default value for
			// our return type
			if (!this->IsSet())
			{
				return R{};
			}

			// Our callback functor is set, so invoke it with its context and
			// any additional arguments passed into this invoker
			//
			// More than likely, this will next go into one of the lambdas from
			// our helpers below, which will then either invoke the function
			// pointer stored in the context with the arguments provided to us
			// from *our* callsite; or invoke the member function used to
			// uniquely construct the lambda function below (in util::Bind())
			// with the context as the 'this' pointer and, again, the arguments
			// provided to us just now from *our* callsite.
			//
			// An important thing to note is the emphasis that the arguments
			// other than the context are *not* stored in the callback in any
			// way. This is different than something like std::function and
			// std::bind(), which can do such a thing. Instead, these arguments
			// (perhaps, more importantly, their values) are being passed into
			// the invocation of us, the callback object itself, by the user.
			return this->functor(this->context, std::forward<Argsp>(args)...);
		}
};

namespace util
{
	/**
	 * Makes a callback with a free function
	 *
	 * @param *function
	 *		The free function to invoke
	 *
	 * @return Callback
	 *		The callback
	 */
	template <typename R, typename... Args>
	constexpr Callback<R(Args...)> Function(R(*function)(Args...))
	{
		// Make a callback with the incoming free function as the context and
		// our lambda as the functor
		//
		// It is likely tempting to think that we should (or could) just store
		// the incoming function pointer itself as the functor in the callback
		// and have the util::Callback class automatically invoke it for us, but
		// because util::Callback is built to allow for the util::Bind() use
		// case, it will always expect a functor that has all of the parameter
		// types of the incoming function *plus* the additional type of the
		// context, meaning the incoming function's signature simply doesn't
		// match the signature of the functor that the callback can take in.
		// Thus, we must always roll our own lambda function to invoke the
		// function.
		return Callback<R(Args...)>(
			reinterpret_cast<void *>(function),
			[](void *context, Args... args) -> R
			{
				return reinterpret_cast<R(*)(Args...)>(context)(args...);
			}
		);
	}

	/**
	 * Helps our bind callback creator
	 *
	 * This is the non-const variant.
	 *
	 * @tparam F
	 *		The member function of the incoming class type/object to invoke
	 * @tparam T
	 *		The class of the object containing the member function
	 * @tparam R
	 *		The return type of the function to invoked
	 * @tparam ...Args
	 *		The argument types of the function to invoked
	 *
	 * @param &item
	 *		An instance of the class whose member function we'll invoke
	 * @param *function
	 *		The class member function to invoke when the callback is invoked
	 *		(only to help resolve the types; this isn't itself used)
	 *
	 * @return Callback
	 *		The callback
	 */
	template <auto F, typename T, typename R, typename... Args>
	constexpr Callback<R(Args...)> _BindHelper(T &item, R(T::*function)(Args...))
	{
		// Make a callback with the incoming class instance as the context and
		// our lambda as the functor
		//
		// This means that when the callback object itself (which we return here
		// to the caller of util::Bind()) is invoked, util::Callback::operator()
		// will invoke *this* lambda function below with the pointer to our
		// object instance as the context. Then we'll invoke the member function
		// on the object, passing along all of the arguments provided to the
		// callsite for the invocation of the callback object. This is
		// unfortunately necessary, as C++ simply doesn't allow (or, at least,
		// want to allow) taking an actual pointer to a member function. The
		// only way we can actually invoke the member function we're being
		// "bound" to is to instantiate this templated lambda function at the
		// callsite of util::Bind().
		return Callback<R(Args...)>(
			static_cast<void *>(&item),
			[](void *context, Args... args) -> R
			{
				return (static_cast<T *>(context)->*F)(args...);
			}
		);
	}

	/**
	 * Helps our bind callback creator
	 *
	 * This is the const variant.
	 *
	 * @tparam F
	 *		The member function of the incoming class type/object to invoke
	 * @tparam T
	 *		The class of the object containing the member function
	 * @tparam R
	 *		The return type of the function to invoked
	 * @tparam ...Args
	 *		The argument types of the function to invoked
	 *
	 * @param &item
	 *		An instance of the class whose member function we'll invoke
	 * @param *function
	 *		The class member function to invoke when the callback is invoked
	 *		(only to help resolve the types; this isn't itself used)
	 *
	 * @return Callback
	 *		The callback
	 */
	template <auto F, typename T, typename R, typename... Args>
	constexpr Callback<R(Args...)> _BindHelper(const T &item, R(T::*function)(Args...) const)
	{
		// Note that the const_cast() here is okay, as the util::Callback class
		// itself must choose either to const- or not const-, and chooses to
		// const-, but itself doesn't violate anything related to the const-ness
		// (that is, we're ultimately the ones to invoke the const-qualified
		// member function F, which we'll only do once we've reapplied the
		// const-ness at our callsite below)
		return Callback<R(Args...)>(
			static_cast<void *>(const_cast<T *>(&item)),
			[](void *context, Args... args) -> R
			{
				return (static_cast<const T *>(context)->*F)(args...);
			}
		);
	}

	/**
	 * Binds an object to one of its class' member functions
	 *
	 * This is the non-const variant.
	 *
	 * @tparam F
	 *		The class member function to bind
	 * @tparam T
	 *		The class of the object
	 *
	 * @param &item
	 *		The item whose member function to bind
	 *
	 * @return Callback
	 *		The callback
	 */
	template <auto F, typename T>
	constexpr auto Bind(T &item)
	{
		return _BindHelper<F>(item, F);
	}

	/**
	 * Binds an object to one of its class' member functions
	 *
	 * This is the const variant.
	 *
	 * @tparam F
	 *		The class member function to bind
	 * @tparam T
	 *		The class of the object
	 *
	 * @param &item
	 *		The item whose member function to bind
	 *
	 * @return Callback
	 *		The callback
	 */
	template <auto F, typename T>
	constexpr auto Bind(const T &item)
	{
		return _BindHelper<F>(item, F);
	}
}
