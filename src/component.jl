_get_value(x) = x
_get_value(x::AbstractObservable) = x[]
_get_value(x::AbstractDict) = Dict(key => _get_value(val) for (key, val) in x)
_get_value(x::NamedTuple) = map(_get_value, x)

function bulmascope()
    Scope(imports = ["https://www.gitcdn.xyz/repo/piever/InteractResources/v0.4.0/bulma/main_confined.min.css"])
end

function addreactivity!(scp::Scope, tag, children...; forceclasses = String[],
    id = string("reactivenode-", uuid4()), properties...)

    n = node(tag, children...; id = id, map(_get_value, values(properties))...)

    addclasses = js"""
    var classes = $forceclasses;
    for (var c of classes) {
        if (!targetNode.classList.contains(c)) {targetNode.classList.add(c);}
    }
    """

    onmount(scp, js"""
    function () {
        var targetNode = _webIOScope.dom.querySelector('#'+$id);
        this.targetNode = targetNode;
        $addclasses
        var callback = function(mutationsList, observer) {
            for (var mutation of mutationsList) {
                if (mutation.type == 'attributes' && mutation.attributeName == 'class') {
                    $addclasses
                }
            }
        };
        var observer = new MutationObserver(callback);
        observer.observe(targetNode, {attributes: true});
    }
    """)
    for (key, val) in properties
        key in (:style, :attributes, :events) && continue
        val isa AbstractObservable || continue
        skey = string(key)
        setobservable!(scp, skey, observe(val))
        onjs(scp[skey], js"""
        function (val) {
            _webIOScope.targetNode[$skey] = val;
        }
        """)
    end

    for propkey in (:attributes, :style)
        dict = get(properties, propkey, Dict())
        for (key, val) in pairs(dict)
            val isa AbstractObservable || continue
            skey, spropkey = string(key), string(propkey)
            obskey = spropkey*"."*skey
            setobservable!(scp, obskey, observe(val))
            onjs(scp[obskey], js"""
            function (val) {
                _webIOScope.targetNode[$spropkey][$skey] = val;
            }
            """)
        end
    end
    scp.dom = n
    return
end
