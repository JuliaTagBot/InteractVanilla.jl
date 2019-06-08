module InteractVanilla

using WebIO: node, Node, instanceof, props, children, Scope, JSString, @js_str, onimport,
             setobservable!, onjs, onmount, WebIO
using Widgets: AbstractWidget, Widget, Widgets, scope
using Observables: on, Observable, AbstractObservable, ObservablePair, observe, Observables
using Dates
using Colors: Colorant, hex
using UUIDs: uuid4

import JSON

include("component.jl")
include("input.jl")

end # module
