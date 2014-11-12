//
// Copyright 2014 Netatmo
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#ifndef weatherstation_NAGlobalDefines_h
#define weatherstation_NAGlobalDefines_h


#define NTAPRINT(xx, ...)  ((void)0)

#define NADPRINTMETHODNAME()  ((void)0)


#if NTALOGLEVEL_ERROR <= NTAMAXLOGLEVEL
#define NTAERROR(xx, ...)  NTAPRINT(xx, ##__VA_ARGS__)
#else
#define NTAERROR(xx, ...)  ((void)0)
#endif // NTALOGLEVEL_ERROR <= NTAMAXLOGLEVEL

#if NTALOGLEVEL_WARNING <= NTAMAXLOGLEVEL
#define NTAWARNING(xx, ...)  NTAPRINT(xx, ##__VA_ARGS__)
#else
#define NTAWARNING(xx, ...)  ((void)0)
#endif // #if NTALOGLEVEL_WARNING <= NTAMAXLOGLEVEL


#ifndef NTAMAXLOGLEVEL
#define NTAMAXLOGLEVEL NTALOGLEVEL_WARNING
#endif

#if NTALOGLEVEL_INFO <= NTAMAXLOGLEVEL
#define NTAINFO(xx, ...)  NTAPRINT(xx, ##__VA_ARGS__)
#else
#define NTAINFO(xx, ...)  ((void)0)
#endif // #if NTALOGLEVEL_INFO <= NTAMAXLOGLEVEL


#ifndef NTAASSERT
#define NTAASSERT(xx, ...)  ((void)0)
#endif

#endif
