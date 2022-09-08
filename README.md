# dclone
Simple utility to clone objects.

## Cloning things
Cloning an object means you create another functionally equivalent object that doesn't share any indirections from the original one. In particular cloned objects can be safely casted to `immutable` and sent to different threads.

In order to clone your variable/struct/array/object you should simply call its `clone` property function:

```d
    class B{
        public:
        char c;
        this() pure @safe{
            c = 'A';
        }

        B clone() const pure @safe{
            auto ret = new B();
            ret.c = c;
            return ret;
        }
    }

    struct A{
        int[] a = null;
        int *b = null;
        B c = null;
    }

    A v;
    v.a = new int[](1);
    v.a[0] = 2;
    v.b = new int(2);

    A w = v.clone;
    assert(w.a[0] == 2 && *(w.b) == 2 && w.c is null, "Not clone");
    w.a[0] = 3;
    *(w.b) = 4;
    w.c = new B();
    B n = w.c.clone;
    n.c = 'C';
    assert(v.a[0] == 2 && *(v.b) == 2, "Shared 1");
    assert(w.a[0] == 3 && *(w.b) == 4 && w.c.c == 'A', "Shared 2");
```

This module provides standard clone functions for integer types, arrays, pointers, POD structs and some auxilary types in Phobos. If you want to make your class or struct cloneable you should define a custom `clone` method as explained in next section.

## Provide your cloning algorithm
By default clonation of a struct is done by cloning each of its fields, so it doesn't work if your struct has `const` or `immutable` member variables. Also this memberwise trivial clonation is not allowed on classes.

In these cases you should provide a custom algorithm to perform a clonation of your object of type `T`, you can use one of the following approaches:

 - declaring a function with signature `clone(in T) pure @safe` at module scope;
 - declaring a method `clone() const pure @safe scope` inside `T`. The `scope` attribute means `this` doesn't escape from `clone`.

Usually return type of these functions should be convertible to `T` (without any `const` or `immutable` qualifiers) but this is not normally enforced.

## cloneNull
When you need to clone a class usually you can simply call `obj.clone`. However this won't work if `obj` is `null`, for this reason when you need to clone an object that can be `null` you should instead use `cloneNull(obj)`: it returns `obj.clone` when `obj` is not `null` and `null` otherwise.
