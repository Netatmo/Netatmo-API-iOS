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

#ifndef NAAPI_NAAPIFlags_h
#define NAAPI_NAAPIFlags_h


#define AF_LOGGER_ENABLE                0

/**
 You can use the folowing log level. See AFNetworkingActivityLogger.h for more information.
 
AFLoggerLevelOff,
AFLoggerLevelDebug,
AFLoggerLevelInfo,
AFLoggerLevelWarn,
AFLoggerLevelError,
AFLoggerLevelFatal = AFLoggerLevelOff,
*/

#if AF_LOGGER_ENABLE
#define AF_LOGGER_LEVEL AFLoggerLevelDebug
#endif

#endif
