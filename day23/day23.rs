use bitvec::bitvec;
use bitvec::vec::BitVec;
use std::collections::{HashMap, HashSet, VecDeque};
use std::{fmt, io};

#[derive(Clone, Copy, Debug, Hash, PartialEq, Eq)]
struct Pos {
    row: usize,
    col: usize,
}

impl fmt::Display for Pos {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "({}, {})", self.row, self.col)
    }
}

#[derive(Debug)]
struct Edge {
    to: Pos,
    distance: i32,
}

impl fmt::Display for Edge {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "({}, dist {})", self.to, self.distance)
    }
}

fn dfs_longest(maze: &Vec<Vec<char>>, visited: &mut BitVec, from: &Pos, exit: &Pos) -> i32 {
    // println!("entry {:?}; exit {:?}", entry, exit);
    if from == exit {
        return 0;
    }
    let height = maze.len();
    let width = maze[0].len();
    let moves = [(-1, 0, 'v'), (0, -1, '>'), (1, 0, '^'), (0, 1, '<')];
    let Pos { row, col } = *from;

    let valid_moves: Vec<_> = moves
        .into_iter()
        .map(|(dr, dc, reverse_dir)| (row as i32 + dr, col as i32 + dc, reverse_dir))
        .filter(|(nr, nc, reverse_dir)| {
            *nr >= 0
                && *nr < height as i32
                && *nc >= 0
                && *nc < width as i32
                && maze[*nr as usize][*nc as usize] != *reverse_dir
                && maze[*nr as usize][*nc as usize] != '#'
                && !visited[(nr * width as i32 + nc) as usize]
        })
        .map(|(r, c, _)| Pos {
            row: r as usize,
            col: c as usize,
        })
        .collect();

    valid_moves
        .into_iter()
        .map(|next| {
            // println!("next {:?}, width {}", next, width);
            let offset = (next.row * width + next.col) as usize;
            // side effect!
            visited.set(offset, true);
            let steps = dfs_longest(maze, visited, &next, exit);
            visited.set(offset, false);
            steps + 1
        })
        .max()
        .unwrap_or(std::i32::MIN)
}

// No, for finding the longest path in a graph, Dijkstra only works if it's a DAG :)
fn dfs_longest_graph(
    graph: &HashMap<Pos, Vec<Edge>>,
    visited: &mut HashSet<Pos>,
    from: Pos,
    to: Pos,
) -> i32 {
    if from == to {
        return 0;
    }
    let moves: Vec<_> = graph[&from]
        .iter()
        .filter(|edge| !visited.contains(&edge.to))
        .collect();
    moves
        .iter()
        .map(|next| {
            visited.insert(from);
            let distance = dfs_longest_graph(graph, visited, next.to, to);
            visited.remove(&from);
            distance + next.distance
        })
        .max()
        .unwrap_or(std::i32::MIN)
}

fn build_graph(maze: &Vec<Vec<char>>, entry: &Pos, exit: &Pos) -> HashMap<Pos, Vec<Edge>> {
    // println!("entry {:?}; exit {:?}", entry, exit);
    let height = maze.len();
    let width = maze[0].len();
    let moves = [(-1, 0), (0, -1), (1, 0), (0, 1)];

    let mut vertex_queue = VecDeque::new();

    let mut vertices: HashMap<Pos, Vec<Edge>> = HashMap::new();
    let mut visited = HashSet::new();
    vertices.insert(*entry, vec![]);
    visited.insert(*entry);

    vertex_queue.push_back((*entry, *entry));

    while !vertex_queue.is_empty() {
        let (vertex, start) = vertex_queue.pop_front().unwrap();
        visited.insert(start);

        let mut distance = if vertex == start { 0 } else { 1 };
        let Pos { mut row, mut col } = start;

        loop {
            let valid_moves: Vec<_> = moves
                .iter()
                .map(|(dr, dc)| (row as i32 + dr, col as i32 + dc))
                .filter(|(nr, nc)| {
                    *nr >= 0
                        && *nr < height as i32
                        && *nc >= 0
                        && *nc < width as i32
                        && maze[*nr as usize][*nc as usize] != '#'
                })
                .map(|(r, c)| Pos {
                    row: r as usize,
                    col: c as usize,
                })
                .filter(|p| *p != vertex && (!visited.contains(p) || vertices.contains_key(p)))
                .collect();

            if valid_moves.len() == 0 {
                // println!("dead end at {},{}", row, col);
                break;
            }
            if valid_moves.len() == 1 {
                distance += 1;
                let next = valid_moves[0];
                visited.insert(next);
                if next == *exit {
                    // println!("Exit found at {},{}", row, col);
                    let new_edge = Edge { to: next, distance };
                    vertices.get_mut(&vertex).unwrap().push(new_edge);
                    break;
                } else if vertices.contains_key(&next) {
                    // a visited vertex
                    vertices
                        .get_mut(&vertex)
                        .unwrap()
                        .push(Edge { to: next, distance });
                    vertices.get_mut(&next).unwrap().push(Edge {
                        to: vertex,
                        distance,
                    });
                    break;
                }
                row = next.row;
                col = next.col;
                continue;
            }
            // found a new vertex
            let new_vertex = Pos { row, col };
            // println!(
            // "found new vertex {:?}; distance {}; visiting {},{}",
            // new_vertex,
            // distance, row, col
            // );
            vertices.insert(
                new_vertex,
                vec![Edge {
                    to: vertex,
                    distance,
                }],
            );
            vertices.get_mut(&vertex).unwrap().push(Edge {
                to: new_vertex,
                distance,
            });
            for next in valid_moves.iter() {
                vertex_queue.push_back((new_vertex, *next));
            }
            break;
        }
    }
    vertices
}

fn main() {
    let maze: Vec<Vec<char>> = io::stdin()
        .lines()
        .map(|line| line.unwrap().chars().collect())
        .collect();

    let entry = Pos { row: 0, col: 1 };
    let exit = Pos {
        row: maze.len() - 1,
        col: maze[0].len() - 2,
    };

    let mut visited = bitvec![0; maze.len() * maze[0].len()];
    let steps = dfs_longest(&maze, &mut visited, &entry, &exit);
    println!("{}", steps);

    let vertices = build_graph(&maze, &entry, &exit);
    let mut visited_set = HashSet::new();
    println!(
        "{}",
        dfs_longest_graph(&vertices, &mut visited_set, entry, exit)
    );
}
