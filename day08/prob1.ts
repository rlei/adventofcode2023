// Requires Deno to run, not nodejs.
import { readLines } from "https://deno.land/std@0.209.0/io/read_lines.ts"

const lines: string[] = await fromAsync(readLines(Deno.stdin))

// See TC39 proposal https://github.com/tc39/proposal-array-from-async
async function fromAsync<T>(asyncIterator: AsyncIterable<T>): Promise<T[]> {
    const res: T[] = []
    for await(const i of asyncIterator) res.push(i)
    return res
}

function* commandGenerator(commands: string): Generator<string> {
    while(true) {
        for (const c of [...commands]) {
            yield c
        }
    }
}

interface Node {
    left: string
    right: string
}

const instructions = lines[0]

const regex = /(.+) = \((.+), (.+)\)/

const theMap = new Map<string, Node>(
    lines.slice(2).map(l => {
        const res = regex.exec(l)
        if (res) {
            const node: Node = { left: res[2], right: res[3] }
            // console.log(`${res[1]} ${JSON.stringify(node)}`)
            return [res[1], node]
        } else {
            throw new Error(`unrecognized input: ${l}`);
        }
    }))

const nextTurn = commandGenerator(instructions)
var node = theMap.get("AAA")
var steps = 0
for (const turn of nextTurn) {
    // console.log(`${turn} @ ${JSON.stringify(node)}`)
    const nextName = (turn == "L") ? node.left : node.right
    steps++
    if (nextName == "ZZZ") {
        console.log(steps)
        break
    }
    node = theMap.get(nextName)
}