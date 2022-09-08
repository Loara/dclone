module clone;

import std.traits;
import std.typecons;
import std.algorithm : move;

alias MutableType(T) = typeof(lvalueOf!T.clone());

Unconst!T clone(T)(in T el) pure @safe nothrow @nogc if(isBasicType!T){
    return el;
}

/*
    Equivalent to clone unless T is a class and el is null. In that case returns null
*/
MutableType!T cloneNull(T)(in T el) pure @safe{
    static if(is(T == class)){
        if(el is null)
            return null;
        else
            return el.clone();
    }
    else return el.clone();
}

Unconst!T clone(T)(in T el) pure @safe if( is(T == struct) && __traits(isPOD, T) ){
    Unconst!T ret;
    static foreach(mem; FieldNameTuple!T){
        mixin("ret." ~ mem ~ "=cloneNull(el." ~ mem ~ ");");
    }
    return ret;
}

MutableType!T[] clone(T)(scope T[] el) pure @safe{
    auto ret = new MutableType!T[](el.length);
    foreach(i, ref v; el){
        ret[i] = cloneNull(v);
    }
    return ret;
}
MutableType!T[N] clone(T, size_t N)(in T[N] el) pure @safe{
    MutableType!T[N] ret;
    foreach(i, ref v; el){
        ret[i] = cloneNull(v);
    }
    return ret;
}

MutableType!T *clone(T)(scope T * el) pure @safe{
    if(el is null)
        return null;
    auto ret = new MutableType!T[](1);
    ret[0] = (*el).clone();
    return &ret[0];
}

/*
    Creates an immutable clone
*/

immutable(MutableType!T) clone_immutable(T)(in T el) pure @trusted{
    return cast(immutable(MutableType!T)) cloneNull(el);
}

void cloneInPlace(T)(ref T el) pure if(MutableType!T == T){
    T cl = cloneNull(el);
    move(cl, el);
}

/*
    Use this class to safely send clones to different threads
*/

struct CloneSend(T) if(hasUnsharedAliasing!T){
    private:
        alias Tval = Nullable!(shared MutableType!T);
        Tval val;//should be @system
    public:
        @disable this();
        @disable this(ref CloneSend!T);
        this(in T el) pure @trusted{
            val = Tval(cast(shared MutableType!T) cloneNull(el));
        }
        MutableType!T getValue() pure @trusted scope in(!val.isNull, "Value already taken"){
            auto ret = cast(MutableType!T) val.get;
            val.nullify();
            return ret;
        }
}

Nullable!(MutableType!T) clone(T)(in Nullable!T n) pure @safe nothrow @nogc{
    alias Tret = Nullable!(MutableType!T);
    if(n.isNull){
        return Tret();
    }
    else{
        return Tret(n.get.clone());
    }
}

unittest{
    class B{
        public:
        char c;
        this() pure @safe{
            c = 'A';
        }

        B clone() const pure @safe scope{
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
}
