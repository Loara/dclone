# dclone
Simple utility to clone objects

## Cloning things
In order to clone your variable/struct/array/object you should simply pass your object to `cloneObj` function (`icloneObj` if you want an `immutable` object):

```d
    struct A{
        int[] a = null;
    }

    static assert(isCloneable!A, "Trait test failed");
    A v;
    v.a = new int[](1);
    v.a[0] = 2;
    A w = cloneObj(v);
    assert(w.a[0] == 2, "Not clone");
    w.a[0] = 3;
    assert(v.a[0] == 2, "Shared 1");
    assert(w.a[0] == 3, "Shared 2");
```

## Provide your cloning algorithm
By default clonation of a struct is done by simpli cloning each of its fields, so it doesn't work if your struct has `const` or `immutable` member variables. Alsothis memberwise trivial clonation is not allowed on classes.

In these cases you should provide a custom algorithm to perform a clonation of your object of type `T`, you can use one of the following approaches:

 - declaring functions `T clone(in T) pure @safe` and `immutable(T) iclone(in T) pure @safe` at module scope;
 - (if `T` is a struct or a class) declaring methods `T clone() const pure @safe` and `immutable(T) iclone() const pure @safe` inside `T`.

The first approach is useful to define clonation algorithm for objects you don't have access to. For example this module provides simple clonation methods for `Nullable!W` objects.
