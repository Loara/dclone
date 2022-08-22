module clone;

import std.traits;
import std.typecons;

bool hasCloneMethod(T)() pure @safe nothrow @nogc{
    static if(is(T == class) || is(T == struct)){
        return hasMember!(T, "clone") && hasMember!(T, "iclone");
    }
    else return false;
}

bool hasCloneFun(T)() pure @trusted nothrow @nogc{
    T val = void;
    return __traits(compiles, clone(val)) && __traits(compiles, iclone(val));
}

bool isCloneable(T)() pure @safe nothrow @nogc{
    static if(isBasicType!T){
        return true;
    }
    else static if(hasCloneFun!T){
        return true;
    }
    else static if(is(T == W[N], W, size_t N)){
        return isCloneable!(Unconst!W);
    }
    else static if(is(T == W[], W)){
        return isCloneable!(Unconst!W);
    }
    else static if(is(T == W*, W)){
        return isCloneable!(Unconst!W);
    }
    else static if(is(T == class)){
        return hasCloneMethod!T;
    }
    else static if(is(T == struct)){
        return true;
    }
    else return false;
}

auto cloneObj(T)(in T el) pure @trusted{
    alias Traw = Unconst!T;
    static assert(isCloneable!Traw, "This type is not cloneable");
    static if(isBasicType!T){
        return cast(Traw) el;
    }
    else static if(hasCloneFun!T){
        return clone(el);
    }
    else static if(is(T == W[N], W, size_t N)){
        Unconst!W[N] ret;
        foreach(size_t i, ref v; el)
            ret[i] = cloneObj(v);
        return ret;
    }
    else static if(is(T == W[], W)){
        if(el.length == 0){
            Unconst!W[] ret;
            return ret;
        }
        else{
            Unconst!W[] ret = new Unconst!W[](el.length);
            foreach(size_t i, ref v; el)
                ret[i] = cloneObj(v);
            return ret;
        }
    }
    else static if(is(T == W*, W)){
        Unconst!W[] may = new Unconst!W[](1);
        may[0] = cloneObj(*el);
        return &(may[0]);
    }
    else static if(is(T == class)){
        if(el is null)
            return cast(Traw) null;
        else
            return el.clone;
    }
    else static if(is(T == struct)){
        static if(hasCloneMethod!Traw){
            return el.clone;
        }
        else{
            Traw ret;
            static foreach(string mem; FieldNameTuple!Traw){
                mixin("ret." ~ mem) = cloneObj(mixin("el." ~ mem));
            }
            return ret;
        }
    }
}

auto icloneObj(T)(in T el) pure @trusted{
    alias Traw = Unconst!T;
    static assert(isCloneable!Traw, "This type is not cloneable");
    static if(isBasicType!T){
        return cast(immutableOf!Traw) el;
    }
    else static if(hasCloneFun!T){
        return iclone(el);
    }
    else static if(is(T == W[N], W, size_t N)){
        Unconst!W[N] ret;
        foreach(size_t i, ref v; el)
            ret[i] = cloneObj(v);
        return cast(ImmutableOf!(Unconst!W)[N])ret;
    }
    else static if(is(T == W[], W)){
        if(el.length == 0){
            ImmutableOf!(Unconst!W)[] ret;
            return ret;
        }
        else{
            Unconst!W[] ret = new Unconst!W[](el.length);
            foreach(size_t i, ref v; el)
                ret[i] = cloneObj(v);
            return cast(ImmutableOf!(Unconst!W)[])ret;
        }
    }
    else static if(is(T == W*, W)){
        Unconst!W[] may = new Unconst!W[](1);
        may[0] = cloneObj(*el);
        return cast(ImmutableOf!(Unconst!W) *) &(may[0]);
    }
    else static if(is(T == class)){
        if(el is null)
            return cast(immutable Traw) null;
        else
            return el.iclone;
    }
    else static if(is(T == struct)){
        static if(hasCloneMethod!Traw){
            return el.iclone;
        }
        else{
            Traw ret;
            static foreach(size_t i, ref e; ret.tupleof){
                e = cloneObj(el.tupleof[i]);
            }
            return cast(ImmutableOf!Traw) ret;
        }
    }
}

/*
    some useful cloning functions
*/

Nullable!T clone(T)(in Nullable!T n) pure @safe nothrow @nogc{
    if(n.isNull){
        return Nullable!T();
    }
    else{
        static if(is(T == immutable)){
            return Nullable!T(icloneObj(n.get));
        }
        else{
            return Nullable!T(cloneObj(n.get));
        }
    }
}
immutable(Nullable!T) clone(T)(in Nullable!T n) pure @safe nothrow @nogc{
    if(n.isNull){
        return immutable Nullable!T();
    }
    else{
        return immutable Nullable!T(icloneObj(n.get));
    }
}

unittest{
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
}
