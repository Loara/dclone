module clone;

import std.traits;

bool hasCloneMethod(T)() pure @safe nothrow @nogc{
    static if(is(T == class) || is(T == struct)){
        return hasMember!(T, "clone") && hasMember!(T, "iclone");
    }
    else return false;
}

bool allSimBaseType(T...)() pure @safe nothrow @nogc{
    static if(T.length == 0)
        return true;
    else return isBaseType!(T[0]) && isAssignable!(T[0]) && allSimBaseType!(T[1..$]);
}

bool isCloneable(T)() pure @safe nothrow @nogc{
    static if(isBaseType!T){
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
        static if(hasCloneMethod!T){
            return true;
        }
        else{
            return allSimBaseType!(Fields!T);
        }
    }
    else return false;
}

auto cloneObj(T)(in T el) pure @trusted{
    alias Traw = Unconst!T;
    static assert(isCloneable!Traw, "This type is not cloneable");
    static if(isBaseType!T){
        return cast(Traw) el;
    }
    else static if(is(T == W[N], W, size_t N)){
        Unconst!W[N] ret;
        foreach(size_t i, ref v; el)
            ret[i] = cloneObj(v);
        return ret;
    }
    else static if(is(T == W[], W)){
        Unconst!W[] ret = new Unconst!W[](el.length);
        foreach(size_t i, ref v; el)
            ret[i] = cloneObj(v);
        return ret;
    }
    else static if(is(T == W*, W)){
        Unconst!W[] may = new Unconst!W[](1);
        may[0] = cloneObj(*el);
        return &(may[0]);
    }
    else static if(is(T == class)){
        return el.clone;
    }
    else static if(is(T == struct)){
        static if(hasCloneMethod!Traw){
            return el.clone;
        }
        else{
            Traw ret;
            static foreach(size_t i, ref e; ret.tupleof){
                e = cloneObj(el.tupleof[i]);
            }
            return ret;
        }
    }
}

auto icloneObj(T)(in T el) pure @trusted{
    alias Traw = Unconst!T;
    static assert(isCloneable!Traw, "This type is not cloneable");
    static if(isBaseType!T){
        return cast(immutableOf!Traw) el;
    }
    else static if(is(T == W[N], W, size_t N)){
        Unconst!W[N] ret;
        foreach(size_t i, ref v; el)
            ret[i] = cloneObj(v);
        return cast(ImmutableOf!(Unconst!W)[N])ret;
    }
    else static if(is(T == W[], W)){
        Unconst!W[] ret = new Unconst!W[](el.length);
        foreach(size_t i, ref v; el)
            ret[i] = cloneObj(v);
        return cast(ImmutableOf!(Unconst!W)[])ret;
    }
    else static if(is(T == W*, W)){
        Unconst!W[] may = new Unconst!W[](1);
        may[0] = cloneObj(*el);
        return cast(ImmutableOf!(Unconst!W) *) &(may[0]);
    }
    else static if(is(T == class)){
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
