import Foundation

enum Pulse {
    case low
    case high
}

typealias PulseOnBus = (pulse: Pulse, from: String, to: String)

protocol Module {
    var name: String { get }
    var outputs: [String] { get }
    
    func signal(pulse: Pulse, from: String)

    func process() -> [PulseOnBus]
}

extension Module {
    func deliverSignal(_ pulse: Pulse) -> [PulseOnBus] {
        outputs.map { PulseOnBus(pulse, self.name, $0) }
    }
}

class Broadcaster: Module {
    let name: String = "broadcaster"
    let outputs: [String]
    
    init(_ outputs: [String]) {
        self.outputs = outputs
    }

    func signal(pulse: Pulse, from: String) {
        assert(pulse == .low)
        assert(from == "button")
    }

    func process() -> [PulseOnBus] {
        self.deliverSignal(.low)
    }
}

// Classes are reference types in Swift, while structs value types.
// Modules need to be of reference types as we're going to store and fetch
// them to/from Dictionary.
// Strictly speaking, immutable modules like Broadcaster and Output may
// still be of a struct type, but that will be inefficient because of the
// copying.
class FlipFlop: Module {
    let name: String
    let outputs: [String]
    var on: Bool
    var flipped: Bool
    
    init(name: String, outputs: [String]) {
        self.name = name
        self.outputs = outputs
        on = false
        flipped = false
    }

    func signal(pulse: Pulse, from: String) {
        if pulse == .low {
            flipped = true
        }
    }

    func process() -> [PulseOnBus] {
        if flipped {
            flipped = false
            on = !on
            return deliverSignal(on ? .high : .low)
        }
        return []
    }
}

class Conjunction: Module {
    let name: String
    var inputRegisters: [String: Pulse]
    let outputs: [String]
    
    init(name: String, inputs: [String], outputs: [String]) {
        self.name = name
        self.inputRegisters = Dictionary(uniqueKeysWithValues: inputs.map {($0, .low)})
        self.outputs = outputs
    }

    func signal(pulse: Pulse, from: String) {
        inputRegisters[from] = pulse
    }

    func process() -> [PulseOnBus] {
        deliverSignal(inputRegisters.allSatisfy { $0.value == .high } ? .low : .high)
    }
}

class Dummy: Module {
    let name: String
    let outputs: [String]
    
    init(_ name: String) {
        self.name = name
        outputs = []
    }

    func signal(pulse: Pulse, from: String) {
        // print("\(from) -\(pulse)- => \(name); ")
    }

    func process() -> [PulseOnBus] {
        []
    }

}

func buildModules() -> [String: Module] {
    var modules: [String: Module] = [:]
    var inputToOutputs: [String: [String]] = [:]
    var conjunctionNames: Set<String> = []

    while let line = readLine() {
        let parts = line.split(separator: " -> ")
        let (name, outputs) = (String(parts[0]), parts[1].split(separator: ", ").map { String($0) })
        switch name {
            case "broadcaster":
                modules[name] = Broadcaster(outputs)
                inputToOutputs[name] = outputs

            case _ where name.starts(with: "%"):
                let flipFlopName = String(name.dropFirst())
                modules[flipFlopName] = FlipFlop(name: flipFlopName, outputs: outputs)
                inputToOutputs[flipFlopName] = outputs

            case _ where name.starts(with: "&"):
                let conjunctionName = String(name.dropFirst())
                conjunctionNames.insert(conjunctionName)
                inputToOutputs[conjunctionName] = outputs

            default:
                // impossible
                fatalError("bad name " + name)
        }
    }

    let conjunctionToInputs = Dictionary(
        grouping: inputToOutputs.flatMap
            { (input, outputs) in outputs.map { ($0, input)} }
            .filter { (output, _) in conjunctionNames.contains(output) },
        by: { $0.0 })
        .mapValues { $0.map { $0.1 }}

    conjunctionToInputs.forEach { (conjunction, inputs) in
        modules[conjunction] = Conjunction(name: conjunction, inputs: inputs, outputs: inputToOutputs[conjunction]!)}

    // at this point, any output that's not in the modules is untyped (output, dummy etc)
    let untypedOutputs = inputToOutputs.flatMap { (_, outputs) in outputs}
        .filter { modules[$0] == nil }
    
    print("found dummy output(s) \(untypedOutputs)")
    untypedOutputs.forEach { modules[$0] = Dummy($0) }

    return modules
}

var modules = buildModules()

var lowPulses = 0
var highPulses = 0

for i in 1...1000 {
    var signalBus = [PulseOnBus(.low, "button", "broadcaster")]

    while !signalBus.isEmpty {
        let (pulse, from, to) = signalBus.removeFirst()
        lowPulses += pulse == .low ? 1 : 0
        highPulses += pulse == .high ? 1 : 0
    
        if to == "rx" && pulse == .low {
            print("rx got low pulse on \(i) presses\n")
        }
        let toModule = modules[to]!
        toModule.signal(pulse: pulse, from: from)
        let created = toModule.process()
        // debugPrint(created, terminator: "\n")
        signalBus.append(contentsOf: created)
    }
    // print("done\n")
}

print("low: \(lowPulses) x high \(highPulses) = \(lowPulses * highPulses)\n")
