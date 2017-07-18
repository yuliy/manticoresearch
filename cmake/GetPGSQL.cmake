#=============================================================================
# Copyright 2017 Manticore Software Ltd.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# This file need to get PGSQL library.
# First it try 'traditional' way - find PostgreSQL lib.
# Then it try to look at 'artefacts' - some packages like ubuntu libpq-dev
# doesn't include catalog/pg_type.h file, and it causes find script
# to fail. However we don't need this file, and we can use lib without it.

if ( WITH_PGSQL_INCLUDES )
	set ( PostgreSQL_INCLUDE_DIR ${WITH_PGSQL_INCLUDES} )
endif ( WITH_PGSQL_INCLUDES )

if ( WITH_PGSQL_LIBS )
	set ( PostgreSQL_LIBRARIES ${WITH_PGSQL_LIBS}/libpq.so )
endif ( WITH_PGSQL_LIBS )

if ( NOT ( WITH_PGSQL_INCLUDES AND WITH_PGSQL_LIBS ))
	find_package ( PostgreSQL )
endif ()

mark_as_advanced ( WITH_PGSQL_INCLUDES WITH_PGSQL_LIBS )

if ( NOT PostgreSQL_FOUND )
	message (STATUS "Not found, use another way...")
	if ( PostgreSQL_INCLUDE_DIR )
		set ( PostgreSQL_INCLUDE_DIRS "${PostgreSQL_INCLUDE_DIR}")
	endif()
	if ( PostgreSQL_LIBRARY_TO_FIND )
		set ( PostgreSQL_LIBRARIES "${PostgreSQL_LIBRARY_TO_FIND}")
	endif()

	if ( PostgreSQL_INCLUDE_DIR AND PostgreSQL_LIBRARY )
		set ( PostgreSQL_FOUND YES )
		message ( STATUS "Found in artefacts." )
	endif()
endif()

if ( NOT PostgreSQL_FOUND )
	if ( APPLE )
		# PostgreSQL_KNOWN_VERSIONS is a gift from previous run of
		# find_package ( PostgreSQL )
		foreach ( suffix ${PostgreSQL_KNOWN_VERSIONS} )
			string ( REPLACE "." "" suffix "${suffix}" )
			list ( APPEND PostgreSQL_ROOT
						"/opt/local/include/postgresql${suffix}" )
		endforeach ()
		find_package ( PostgreSQL )
		if ( NOT PostgreSQL_FOUND )
			message ( STATUS "Not found, use another way..." )
			if ( PostgreSQL_INCLUDE_DIR )
				set ( PostgreSQL_INCLUDE_DIRS "${PostgreSQL_INCLUDE_DIR}" )
			endif ()
			if ( PostgreSQL_LIBRARY_TO_FIND )
				set ( PostgreSQL_LIBRARIES "${PostgreSQL_LIBRARY_TO_FIND}" )
			endif ()

			if ( PostgreSQL_INCLUDE_DIR AND PostgreSQL_LIBRARY )
				set ( PostgreSQL_FOUND YES )
				message ( STATUS "Found in artefacts." )
			endif ()
		endif ()
	endif()
endif ()



if ( NOT PostgreSQL_FOUND )
	message ( SEND_ERROR "********************************************************************************
ERROR: cannot find PostgreSQL libraries. If you want to compile with PosgregSQL support,
you must either specify file locations explicitly using
-D WITH_PGSQL_INCLUDES=... and -D WITH_PGSQL_LIBS=... options, or make sure path to
pg_config is listed in your PATH environment variable. If you want to
disable PostgreSQL support, use -D WITH_PGSQL=OFF option.
********************************************************************************" )

	message ( "PostgreSQL_INCLUDE_DIRS ${PostgreSQL_INCLUDE_DIR}")
	message ( "PostgreSQL_LIBRARY ${PostgreSQL_LIBRARY}" )
	message ( "PostgreSQL_LIBRARY_TO_FIND ${PostgreSQL_LIBRARY_TO_FIND}" )

endif()

# For this moment lib is found.

set ( USE_PGSQL 1 )
include_directories ( ${PostgreSQL_INCLUDE_DIRS} )

CMAKE_DEPENDENT_OPTION ( DL_PGSQL "load pgsql library dynamically" ON "PostgreSQL_FOUND;HAVE_DL;NOT STATIC_PGSQL" OFF )
CMAKE_DEPENDENT_OPTION ( STATIC_PGSQL "link to pgsql library statically" OFF "PostgreSQL_FOUND;NOT DL_PGSQL" OFF )
if ( STATIC_PGSQL )
	message ( STATUS "PosgreSQL will be linked statically" )
	string ( REGEX REPLACE "pq" "libpq.a" PostgreSQL_LIBRARIES "${PostgreSQL_LIBRARIES}" )
endif ( STATIC_PGSQL )

if ( DL_PGSQL )
	message ( STATUS "PosgreSQL will not be linked (will be loaded at runtime)" )
	set ( DL_PGSQL 1 )
	GET_FILENAME_COMPONENT ( PGSQL_LIB ${PostgreSQL_LIBRARY} NAME )
else ( DL_PGSQL )
	list ( APPEND EXTRA_LIBRARIES ${PostgreSQL_LIBRARIES} )
endif ()

mark_as_advanced(PostgreSQL_CONFIG_DIR PostgreSQL_LIBRARY PostgreSQL_TYPE_INCLUDE_DIR)