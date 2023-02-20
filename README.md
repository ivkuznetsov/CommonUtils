# CommonUtils
> Helpful code commonly used in the apps to simplify things.

## Keychain

Storing and retrieving data in Keychain.

```swift
Keychain.set(string: "my key", service: "app.service")
        
let key = Keychain.get("app.service")
```

## RWAtomic

Atomic property wrapper for concurrent reading and synchronized writing. Based on pthread_rwlock.

```swift
@RWAtomic var array: [String] = []

_array.mutate {
    $0.append("new")
}
```

## Meta

Ilya Kuznetsov – i.v.kuznecov@gmail.com

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/ivkuznetsov](https://github.com/ivkuznetsov)
