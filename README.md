Weather Station Sample App - iOS
========

Sample application that implements the Netatmo API available here: http://dev.netatmo.com/doc/

It contains two packages:
 * [__Library__][1]: Classes to get you started with our API including a http client and some parsing utilities. This implementation provides tools to get the last measurements for a given device.
 * [__ViewController__][2]: A quick example of what you can do with the __Library__ package.


Explanation & Usage
--------

1. Register your Netatmo application: http://dev.netatmo.com/dev/createapp.
2. Start developing your app like in the sample. Do not forget to put your CLIENT_ID and your CLIENT_SECRET in [__NAAPIConfig.h__][3].

Each request is made using __AFNetworking__.


Requirements
--------
1. Target API : 8.1
2. Minimum API : 8.1


Credits
--------
 * AFNetworking : https://github.com/AFNetworking/AFNetworking


License
--------

    Copyright 2014 Netatmo
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


[1]: SampleAPIApp/Library
[2]: SampleAPIApp/ViewController
[3]: SampleAPIApp/Library/NAAPI/NAAPIConfig.h