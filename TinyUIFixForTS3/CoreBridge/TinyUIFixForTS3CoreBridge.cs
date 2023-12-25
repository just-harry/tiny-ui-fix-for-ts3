
/* SPDX-LICENSE-IDENTIFIER: BSL-1.0 */

/*
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
*/

namespace TinyUIFixForTS3CoreBridge
{
	public delegate void UIEventRegistrationChangeEventHandler (uint windowHandle, uint eventType, uint eventChangeType);

	public enum UIEventRegistrationChangeType : uint
	{
		EventRegistered = 0,
		EventDeregistered = 1,
		AllEventsDeregistered = 2
	}
}

