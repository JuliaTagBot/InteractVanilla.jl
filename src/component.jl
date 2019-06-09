_get_value(x) = x
_get_value(x::AbstractObservable) = x[]
_get_value(x::AbstractDict) = Dict(key => _get_value(val) for (key, val) in x)
_get_value(x::NamedTuple) = map(_get_value, x)

function addreactivity!(scp::Scope, tag, children...; addevents = Dict(),
    id = string("reactivenode-", uuid4()), properties...)

    n = node(tag, children...; id = id, map(_get_value, values(properties))...)

    onmount(scp, js"""
    function() {
        var node = _webIOScope.dom.querySelector('#'+$id)
        var events = $addevents;
        for (var key of Object.keys(events)) {
            node.addEventListener(key, events[key]);
        }
    }
    """)

    specialprops = (:style, :attributes, :events)
    for (key, val) in properties
        key in specialprops && continue
        val isa AbstractObservable || continue
        skey = string(key)
        setobservable!(scp, skey, observe(val))
        onjs(scp[skey], js"""
        function (val) {
            var node = _webIOScope.dom.querySelector('#'+$id)
            node[$skey] = val;
        }
        """)
    end

    for propkey in specialprops
        dict = get(properties, propkey, Dict())
        for (key, val) in pairs(dict)
            val isa AbstractObservable || continue
            skey, spropkey = string(key), string(propkey)
            obskey = spropkey*"."*skey
            setobservable!(scp, obskey, observe(val))
            onjs(scp[obskey], js"""
            function (val) {
                var node = _webIOScope.dom.querySelector('#'+$id)
                node[$spropkey][$skey] = val;
            }
            """)
        end
    end
    scp.dom = n
    return
end
