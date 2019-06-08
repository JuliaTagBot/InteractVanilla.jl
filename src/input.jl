const updatevalue = js"function () {_webIOScope.setObservableValue('value', this.value);}"
const countchanges = js"""
function () {
    var val = _webIOScope.getObservableValue('changes') + 1;
    _webIOScope.setObservableValue('changes', val);
}
"""

function input(;
               events = Dict(:input => updatevalue, :change => countchanges),
               value = "",
               type = "text",
               kwargs...)

    value isa AbstractObservable || (value = Observable(value))

    scp = bulmascope()
    setobservable!(scp, "changes", Observable(0))
    addreactivity!(scp, :input; forceclasses = ["input"], events = events, value = value, type = type, kwargs...)

    Widget{:input}(
        scope = scp,
        output = value,
        layout = x -> node(:div, scope(x), className = "interact-widget")
    )
end
