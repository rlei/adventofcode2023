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

function primeFactors(n: number): number[] {
    const factors: number[] = [];
    let divisor = 2;

    while (n >= 2) {
      if (n % divisor == 0) {
        factors.push(divisor);
        while (n % divisor == 0) {
            n = n / divisor;
        }
      } else {
        divisor++;
      }
    }
    return factors;
  }

function findSteps(map: Map<string, Node>, start: string, turnGenerator: Generator<string>): number {
    var node = theMap.get(start)
    var steps = 0
    for (const turn of turnGenerator) {
        // console.log(`${turn} @ ${JSON.stringify(node)}`)
        const nextName = (turn == "L") ? node.left : node.right
        steps++
        node = theMap.get(nextName)
        if (nextName.endsWith("Z")) {
            console.log(`${start} => ${nextName}: ${steps}`)
            break
        }
    }
    return steps
}

const startNodes = Array.from(theMap.entries()).filter(kv => kv[0].endsWith("A"));
console.log(startNodes)

const factors = new Set(
    startNodes.map(startNode => {
        const nextTurn = commandGenerator(instructions)
        const factors = primeFactors(findSteps(theMap, startNode[0], nextTurn))
        console.log(factors)
        return factors
    })
    .flat())

// Note it is in fact NOT correct to just calculate the LCM of all steps, because
// there's no guarantee that from **A to **Z and from **Z back to **Z both take
// the same steps. It would require to solve the linear equations like:
//  Eq 1: step_11A_to_11Z + u * step_11Z_to_11Z = total_steps
//  Eq 2: step_22A_to_22Z + v * step_22Z_to_22Z = total_steps
//  ...
//  Eq 5: step_55A_to_55Z + z * step_55Z_to_55Z = total_steps
//  Eq 6: step_66A_to_66Z + z * step_66Z_to_66Z = total_steps
// which may or may not be solvable on Z+
// However this does work for the AoC day 8 input, which is kindly designed so that
// each **A to **Z and **Z to **Z pair have the same steps.

console.log([...factors].reduce((a, b) => a * b))
