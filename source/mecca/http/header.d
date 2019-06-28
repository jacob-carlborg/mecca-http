/**
 * HTTP header.
 *
 * Copyright: Copyright (c) 2019 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module mecca.http.header;

struct Header
{
    package enum immutable(void)[] endSentinel = "\r\n\r\n";
}
