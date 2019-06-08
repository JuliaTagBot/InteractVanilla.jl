_get_value(x) = x
_get_value(x::AbstractObservable) = x[]
_get_value(x::AbstractDict) = Dict(key => _get_value(val) for (key, val) in x)

function addreactivity!(s::Scope, tag, children...;
    id = string("reactivenode-", uuid4()), properties...)

    n = node(tag, children...; id = id, map(_get_value, values(properties))...)

    for (key, val) in properties
        key in (:style, :attributes, :events) && continue
        val isa AbstractObservable || continue
        skey = string(key)
        setobservable!(s, skey, observe(val))
        onjs(s[skey], js"""
        function (val) {
            var node = _webIOScope.dom.querySelector("#"+$id);
            node[$skey] = val;
        }
        """)
    end

    for propkey in (:attributes, :style)
        dict = get(properties, propkey, Dict())
        for (key, val) in dict
            val isa AbstractObservable || continue
            skey, spropkey = string(key), string(propkey)
            obskey = spropkey*"."*skey
            setobservable!(s, obskey, observe(val))
            onjs(s[obskey], js"""
            function (val) {
                var node = _webIOScope.dom.querySelector("#"+$id);
                node[$spropkey][$skey] = val;
            }
            """)
        end
    end

    return n
end
