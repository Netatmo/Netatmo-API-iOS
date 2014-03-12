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

const int  NAAPIUnitUs = 1;
const int  NAAPIRadioThreshold3 = 50;
const int  NAAPIKindReadTimeline = 0;
const int  NAAPIUnitWindMph = 1;
const int  NAAPIUnitTypeNumber = 2;
const int  NAAPIUnitWindNumber = 5;
const int  NAAPIRssiThreshold1 = 60;
const int  NAAPIUnitWindMs = 2;
const int  NAAPIKindBothTimeline = 2;
const int  NAAPIRadioThreshold1 = 70;
const int  NAAPIRadioThreshold2 = 60;
const int  NAAPIKindNotReadTimeline = 1;
const int  NAAPIUnitMetric = 0;
const int  NAAPIUnitWindKmh = 0;
const int  NAAPIRssiThreshold0 = 80;
const int  NAAPIUnitWindBeaufort = 3;
const int  NAAPIUnitWindKnot = 4;
const int  NAAPIRssiThreshold2 = 40;
const int  NAAPIRadioThreshold0 = 80;

const NSString* const NAAPIScopeReadStation = @"read_station";
const NSString* const NAAPIScopeReadTherm = @"read_thermostat";
const NSString* const NAAPIScopeWriteTherm = @"write_thermostat";