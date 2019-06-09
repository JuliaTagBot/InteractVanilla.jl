const updatevalue = js"function () {_webIOScope.setObservableValue('value', this.value);}"
const countchanges = js"""
function () {
    var val = _webIOScope.getObservableValue('changes') + 1;
    _webIOScope.setObservableValue('changes', val);
}
"""

function input(;
               imports = String[],
               addevents = Dict(:input => updatevalue, :change => countchanges),
               value = "",
               kwargs...)

    value isa AbstractObservable || (value = Observable(value))

    scp = Scope(imports = imports)
    setobservable!(scp, "changes", Observable(0))
    addreactivity!(scp, :input; addevents = addevents, value = value, kwargs...)

    Widget{:input}(
        scope = scp,
        output = value,
        layout = x -> node(:div, scope(x), className = "interact-widget")
    )
end
