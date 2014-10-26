/*
 * Copyright (c) 2003-2004 Apple Computer, Inc. All Rights Reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 *
 * readline.c
 */

#include "readline.h"
#include "security.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Read a line from stdin into buffer as a null terminated string.  If buffer is
   non NULL use at most buffer_size bytes and return a pointer to buffer.  Otherwise
   return a newly malloced buffer.
   if EOF is read this function returns NULL.  */
char *
readline(char *buffer, int buffer_size)
{
	int ix = 0, bytes_malloced = 0;

	if (!buffer)
	{
		bytes_malloced = 64;
		buffer = (char *)malloc(bytes_malloced);
		buffer_size = bytes_malloced;
	}

	for (;;++ix)
	{
		int ch;

		if (ix == buffer_size - 1)
		{
			if (!bytes_malloced)
				break;
			bytes_malloced += bytes_malloced;
			buffer = (char *)realloc(buffer, bytes_malloced);
			buffer_size = bytes_malloced;
		}

		ch = getchar();
		if (ch == EOF)
		{
			if (bytes_malloced)
				free(buffer);
			return NULL;
		}
		if (ch == '\n')
			break;
		buffer[ix] = ch;
	}

	/* 0 terminate buffer. */
	buffer[ix] = '\0';

	return buffer;
}
