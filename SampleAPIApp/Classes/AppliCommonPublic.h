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


#ifndef __weatherstation_AppliCommonPublic_h__
#define __weatherstation_AppliCommonPublic_h__

typedef enum {
    NtmoAPIErrorCodeOauthOther = -2,
    NtmoAPIErrorCodeOauthInvalidGrant = -1,
    NtmoAPIErrorCodeAccessTokenMissing = 1,
    NtmoAPIErrorCodeInvalidAccessToken = 2,
    NtmoAPIErrorCodeAccessTokenExpired = 3,
    NtmoAPIErrorCodeInconsistencyError = 4,
    NtmoAPIErrorCodeApplicationDeactivated = 5,
    NtmoAPIErrorCodeInvalidEmail = 6,
    NtmoAPIErrorCodeNothingToModify = 7,
    NtmoAPIErrorCodeEmailAlreadyExists = 8,
    NtmoAPIErrorCodeDeviceNotFound = 9,
    NtmoAPIErrorCodeMissingArgs = 10,
    NtmoAPIErrorCodeInternalError = 11,
    NtmoAPIErrorCodeDeviceOrSecretNoMatch = 12,
    NtmoAPIErrorCodeOperationForbidden = 13,
    NtmoAPIErrorCodeApplicationNameAlreadyExists = 14,
    NtmoAPIErrorCodeNoPlacesInDevice = 15,
    NtmoAPIErrorCodeMgtKeyMissing = 16,
    NtmoAPIErrorCodeBadMgtKey = 17,
    NtmoAPIErrorCodeDeviceIdAlreadyExists = 18,
    NtmoAPIErrorCodeIpNotFound = 19,
    NtmoAPIErrorCodeTooManyUserWithIp = 20,
    NtmoAPIErrorCodeInvalidArg = 21,
    NtmoAPIErrorCodeApplicationNotFound = 22,
    NtmoAPIErrorCodeUserNotFound = 23,
    NtmoAPIErrorCodeInvalidTimezone = 24,
    NtmoAPIErrorCodeInvalidDate = 25,
    NtmoAPIErrorCodeMaxUsageReached = 26,
    NtmoAPIErrorCodeMeasureAlreadyExists = 27,
    NtmoAPIErrorCodeAlreadyDeviceOwner = 28,
    NtmoAPIErrorCodeInvalidIp = 29,
    NtmoAPIErrorCodeInvalidRefreshToken = 30,
    NtmoAPIErrorCodeNotFound = 31,
    NtmoAPIErrorCodeBadPassword = 32,
    NtmoAPIErrorCodeForceAssociate = 33,

	/*Only for ios, not script generated*/

	NtmoAPIErrorCodeSuccess = 200,
	NtmoAPIErrorCodeUnknown = -10,
	NtmoAPIErrorCodeNoDataConnection = -11
} NtmoAPIErrorCode;

extern const int NAAPIUnitUs;
extern const int NAAPIRadioThreshold3;
extern const int NAAPIKindReadTimeline;
extern const int NAAPIUnitWindMph;
extern const int NAAPIUnitTypeNumber;
extern const int NAAPIUnitWindNumber;
extern const int NAAPIRssiThreshold1;
extern const int NAAPIUnitWindMs;
extern const int NAAPIKindBothTimeline;
extern const int NAAPIRadioThreshold1;
extern const int NAAPIRadioThreshold2;
extern const int NAAPIKindNotReadTimeline;
extern const int NAAPIUnitMetric;
extern const int NAAPIUnitWindKmh;
extern const int NAAPIRssiThreshold0;
extern const int NAAPIUnitWindBeaufort;
extern const int NAAPIUnitWindKnot;
extern const int NAAPIRssiThreshold2;
extern const int NAAPIRadioThreshold0;
#endif
