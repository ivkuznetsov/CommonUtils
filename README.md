# CommonUtils
> Helpful code commonly used in the apps to simplify things.

## Work

NSOperation based tasks management.

Simple block work:

```swift
let work = BlockWork<Int> {
    return try doStuff()
}
work.run { result in
    switch result {
    case .success(let value):
        print(value)
    case .failure(let error):
        print(error)
    }
}
```

Simple async work:

```swift
let asyncWork = AsyncWork<Int> { work in
    
    //do some async stuff
    work.resolve(1)
    
    // if error work.reject(SomeError)
}
```

Works chain:

```swift
let chain = BlockWork<Int> {
    return 1
}.chain { result in
    BlockWork {
        result + 1
    }.chain { result2 in
        BlockWork {
            result2 + 1
        }
    }
}
chain.run() // result = 3
```

Chain with condition

```swift
let workWithCondition = BlockWork<Int> {
    return 1
}.chain { result in
    BlockWork {
        result + 1
    }.chain { result2 in
        
        if result2 > 2 {
            return .value(result2)
        } else {
            return BlockWork {
                result2 + 1
            }
        }
    }
}
```

Singleton chain:

```swift
let singletonWork = BlockWork<Int> {
    return 1
}.chain { result in
    BlockWork {
        result + 1
    }.chain { result2 in
        BlockWork {
            result2 + 1
        }
    }
}.singleton("singltonKey")
```

Group of works:

```swift
GroupWork(works: [work1, work2, work3]).run()
```

Group with results of works
```swift
with(work1, work2) { result1, result2 in
    
}
```

Work with progress:

```swift
let progressWork = AsyncWork<String> { work in
    work.progress.update(0.5)
    work.resolve("result")
}
progressWork.run(progress: { progressValue in
    print("progress: \(progressValue)")
})
```

Custom work:
    
```swift
struct Result { }
    
class MyCustomWork: Work<Result> {
        
    override func execute() {
        //do stuff
        
        resolve(Result())
    }
}
```

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
