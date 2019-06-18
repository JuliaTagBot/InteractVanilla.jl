abstract type AbstractVanillaWidget{T} <: AbstractObservable{T} end
Observables.observe(a::AbstractVanillaWidget) = observe(value(a))
Base.getproperty(a::AbstractVanillaWidget, s::Symbol) = getproperty(props(a), s)
Base.propertynames(a::AbstractVanillaWidget) = propertynames(props(a))

_get_value(x) = x
_get_value(x::AbstractObservable) = x[]
_get_value(x::AbstractDict) = Dict(key => _get_value(val) for (key, val) in x)
_get_value(x::NamedTuple) = map(_get_value, x)

to_observable(o::Observable) = o
to_observable(o::AbstractObservable) = Observables.observe(o)
to_observable(o) = Observable(o)

const specialprops = (:style, :attributes, :events)

observify((key, val)::Pair) = key in specialprops ? (key => to_observable(val)) : (key => val)

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
