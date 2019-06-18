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
               value = Observable(""),
               kwargs...)

    scp = Scope(imports = imports)
    setobservable!(scp, "changes", Observable(0))
    addreactivity!(scp, :input; addevents = addevents, value = value, kwargs...)

    Widget{:input}(
        scope = scp,
        output = value,
        layout = x -> node(:div, scope(x), className = "interact-widget")
    )
end

struct TextBox{T} <: AbstractVanillaWidget{T}
    value::AbstractObservable{T}
    props::Dict{Symbol, Any}
    function TextBox(value::AbstractObservable{T}; className = "input", kwargs...) where {T}
        props = Dict{Symbol, Any}(observify(pair) for pair in kwargs)
        new{T}(value, props)
    end
end
TextBox(value; kwargs...) = TextBox(to_observable(value); kwargs...)

value(a::TextBox) = getfield(a, 1)
WebIO.props(a::TextBox) = getfield(a, 2)

function WebIO.render(a::TextBox)
    input()
