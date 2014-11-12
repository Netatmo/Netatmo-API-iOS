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
    NtmoAPIErrorCodeModuleAlreadyPaired = 34,
    NtmoAPIErrorCodeUnableToExecute = 35,

	/*Only for ios, not script generated*/

	NtmoAPIErrorCodeSuccess = 200,
	NtmoAPIErrorCodeUnknown = -10,
	NtmoAPIErrorCodeNoDataConnection = -11,
	NtmoAPIErrorCodeUserNeedToLogIn = -12
} NtmoAPIErrorCode;

const int  NAAPIUnitMetric = 0;
const int  NAAPIUnitUs = 1;

const int  NAAPIUnitWindKmh = 0;
const int  NAAPIUnitWindMph = 1;

const int  NAAPIUnitPressureMbar = 0;
const int  NAAPIUnitPressureMercury = 1;
