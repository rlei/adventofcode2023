#include <algorithm>
#include <functional>
#include <iostream>
#include <numeric>
#include <queue>
#include <ranges>
#include <set>
#include <string>
#include <tuple>
#include <vector>

template<typename T>
using Map2D = std::vector<std::vector<T>>;

using Pos = std::tuple<int, int>;
using LossAndPos = std::tuple<int, Pos>;
using Path = std::vector<Pos>;
using Paths = std::vector<std::vector<Pos>>;

const auto moves = std::vector<Pos>{{-1, 0}, {0, -1}, {1, 0}, {0, 1}};

constexpr Pos operator+(const Pos& a, const Pos& b) {
    const auto [ar, ac] = a;
    const auto [br, bc] = b;
    return Pos(ar + br, ac + bc);
};

constexpr Pos operator-(const Pos& a, const Pos& b) {
    const auto [ar, ac] = a;
    const auto [br, bc] = b;
    return Pos(ar - br, ac - bc);
}

std::ostream& operator<<(std::ostream& os, const Pos pos) {
    os << "(";
    auto [row, col] = pos;
    os << row << "," << col;
    return os << ")";
}

int dijkstra(const Map2D<int>& map) {
    std::priority_queue<LossAndPos, std::deque<LossAndPos>, std::greater<LossAndPos>> pq;

    const int rows = map.size();
    const int cols = map[0].size();
    const auto start = Pos(0, 0);
    Map2D<int> path_loss_map(rows, std::vector<int>(cols, std::numeric_limits<int>::max()));
    Map2D<Paths> path_map(rows, std::vector<Paths>(cols, Paths{Path{}}));

    std::set<Pos> visited;
    visited.insert(start);
    // start pos is considered 0
    path_loss_map[0][0] = 0;
    pq.push(LossAndPos(0, start));

    auto isValidPos = [&](const auto pos) {
        const auto [row, col] = pos;
        return row >= 0 && row < rows && col >= 0 && col < cols;
    };
    while (!pq.empty()) {
        const auto [loss, pos] = pq.top();
        pq.pop();
        visited.insert(pos);

        const auto [currRow, currCol] = pos;
        auto pathsSoFar = path_map[currRow][currCol];
        std::cout << pos << "; loss " << loss << std::endl;
        for (auto& path : pathsSoFar) {
            path.push_back(pos);
            for (auto pos : path) {
                std::cout << pos << " ";
            }
            std::cout << std::endl;
        }

        auto forbiddenMoves = std::vector<Pos>{}; // assuming no forbidden move
        for (const auto& path : pathsSoFar) {
            if (path.size() > 4) {
                auto moves = std::vector<Pos>(4);
                std::adjacent_difference(path.end() - 4, path.end(), moves.begin(), operator-);
                if (moves[1] == moves[2] && moves[2] == moves[3]) {
                    forbiddenMoves.push_back(moves[1]);
                } else {
                    // There could be multiple paths leading to this position that have the same
                    // minimal loss. If any path doesn't have 3 same directional moves, there will
                    // be no forbidden direction for this move.
                    forbiddenMoves.clear();
                    break;
                }
            }
        }
        
        auto addToPos = std::bind(operator+, pos, std::placeholders::_1);
        auto nextPositions = moves
            | std::views::filter([forbiddenMoves](const Pos& p)
                { return std::find(forbiddenMoves.begin(), forbiddenMoves.end(), p) == forbiddenMoves.end(); })
            | std::views::transform(addToPos)
            | std::views::filter(isValidPos);

        for (auto next : nextPositions) {
            const auto [row, col] = next;
            if (!visited.contains(next)) {
                const auto oldLoss = path_loss_map[row][col];
                const auto newLoss = loss + map[row][col];
                if (newLoss < oldLoss) {
                    // if (row == rows - 1 && col == cols - 1) {
                        // for (auto [r, c] : pathsSoFar[0]) {
                            // std::cout << r << ", " << c << " | " << map[r][c] << std::endl;
                        // }
                        // return newLoss;
                    // }

                    pq.push(LossAndPos(newLoss, next));
                    path_loss_map[row][col] = newLoss;
                    path_map[row][col] = pathsSoFar;
                } else if (newLoss == oldLoss) {
                    // multiple paths leading to the next position
                    path_map[row][col].insert(path_map[row][col].end(), pathsSoFar.begin(), pathsSoFar.end());
                }
            }
        }
    }
    return path_loss_map[rows - 1][cols - 1];
}

int main() {
    Map2D<int> map;

    auto parseCharToInt = [](char c) -> int { return c - '0'; };
    for (std::string line; std::getline(std::cin, line);) {
        auto transformed = line | std::views::transform(parseCharToInt);
        std::vector<int> ints;
        std::ranges::copy(transformed, std::back_inserter(ints));
        map.push_back(ints);

        for (const auto& value : ints) {
            std::cout << value << " ";
        }
        std::cout << std::endl;
    }

    std::cout << dijkstra(map) << std::endl;
    return 0;
}
