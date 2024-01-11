fun dfs(graph: Map<String, Set<String>>, cap: MutableMap<Pair<String, String>, Int>, visited: MutableSet<String>, from: String, to: String): Boolean {
    if (from == to) {
        return true
    }
    visited.add(from)
    for (adj in graph[from]!!) {
        if (cap[Pair(from, adj)]!! <= 0 || visited.contains(adj)) {
            continue
        }

        if (dfs(graph, cap, visited, adj, to)) {
            // https://en.wikipedia.org/wiki/Ford%E2%80%93Fulkerson_algorithm
            cap[Pair(from, adj)] = cap[Pair(from, adj)]!! - 1
            cap[Pair(adj, from)] = cap[Pair(adj, from)]!! + 1
            return true
        }
    }
    return false
}

fun isNEdgeConnected(graph: Map<String, Set<String>>, n: Int, from: String, to: String): Boolean {
    val cap = graph.flatMap { (v, nextVs) -> nextVs.map { Pair(v, it) to 1 } }
        .toMap().toMutableMap()

    repeat(n) {
        val visited = mutableSetOf<String>()
        if (!dfs(graph, cap, visited, from, to)) {
            return false
        }
    }
    return true
}

fun main() {
    val graph = generateSequence(::readLine)
        .flatMap { line ->
            val kv = line.split(": ")
            kv[1].split(' ').flatMap { listOf(kv[0] to it, it to kv[0]) }
        }.groupBy({it.first}, {it.second}).mapValues { (_, v) -> v.toSet() }

//    println("${graph}")
    println("V: ${graph.size}; E: ${graph.values.map{ it.size }.toList().sum() / 2 }")

    val vertices = graph.keys.toList()
    val visited = mutableSetOf<String>()
    val components = mutableMapOf<String, MutableList<String>>()

    vertices.forEach { from ->
        if (!visited.contains(from)) {
            visited.add(from)
            components[from] = mutableListOf(from)
            vertices.forEach { to ->
                if (!visited.contains(to)) {
                    if (isNEdgeConnected(graph, 4, from, to)) {
                        visited.add(to)
                        components[from]!!.add(to)
                    }
                }
            }
//            println("4-edge-connected component: ${components[from]}")
        }
    }
    println("${components.values.map { it.size }.reduce{ acc, n -> acc * n}}")
}
