//
// Copyright 2011-2012 Netatmo
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


#define NTA_RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }


#ifdef DEBUG
    #define NTAPRINT(xx, ...)  NSLog(@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define NTAPRINT(xx, ...)  ((void)0)
#endif

#ifdef DEBUG
#define NADPRINTMETHODNAME()  NSLog(@"%s" , __PRETTY_FUNCTION__)
#else
#define NADPRINTMETHODNAME()  ((void)0)
#endif

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


#define NARequestTimeoutValue 15.0f