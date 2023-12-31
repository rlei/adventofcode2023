#include <algorithm>
#include <functional>
#include <iostream>
#include <map>
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
using Move = std::tuple<int, int>;
// Last move and repeated count
using MoveAndCount = std::tuple<Move, int>;
using PosAndMoves = std::tuple<Pos, MoveAndCount>;
using LossAndPos = std::tuple<int, Pos, MoveAndCount>;
using MovesToLossMap = std::map<MoveAndCount, int>;

const auto possible_moves = std::vector<Move>{{-1, 0}, {0, -1}, {1, 0}, {0, 1}};

std::ostream& operator<<(std::ostream& os, const Pos& pos) {
    os << "(";
    auto [row, col] = pos;
    os << row << "," << col;
    return os << ")";
}

std::ostream& operator<<(std::ostream& os, const MoveAndCount& moveAndCount) {
    auto [move, count] = moveAndCount;
    return os << move << ", " << count << " times";
}

constexpr Pos operator+(const Pos& a, const Move& b) {
    const auto [ar, ac] = a;
    const auto [br, bc] = b;
    return Pos(ar + br, ac + bc);
};

constexpr Move operator-(const Pos& a, const Pos& b) {
    const auto [ar, ac] = a;
    const auto [br, bc] = b;
    return Move(ar - br, ac - bc);
}

constexpr MoveAndCount addMove(const MoveAndCount& last, const Move& thisMove) {
    auto [move, count] = last;
    if (move == thisMove) {
        return {move, count + 1};
    }
    return {thisMove, 1};
}

constexpr bool isValidPos (const Map2D<int>& map, const Pos& pos) {
    const auto [row, col] = pos;
    return row >= 0 && row < map.size() && col >= 0 && col < map[0].size();
};

int dijkstra_last_3(const Map2D<int>& map) {
    std::priority_queue<LossAndPos, std::deque<LossAndPos>, std::greater<LossAndPos>> pq;

    const int rows = map.size();
    const int cols = map[0].size();
    const auto y = 0;
    const auto x = 0;
    const auto start = Pos(y, x);
    Map2D<MovesToLossMap> moves_loss_map(rows, std::vector<MovesToLossMap>(cols, MovesToLossMap{}));
    std::set<PosAndMoves> visited;

    moves_loss_map[y][x] = MovesToLossMap{{{}, 0}};
    pq.push(LossAndPos(map[y][x], start, {}));

    while (!pq.empty()) {
        const auto [loss, pos, lastMoveAndCount] = pq.top();
        pq.pop();
        visited.insert({pos, lastMoveAndCount});

        auto [lastMove, count] = lastMoveAndCount;
        auto forbiddenMoves = std::vector<Move>{};
        // not allow going back
        const auto [lastMoveY, lastMoveX]= lastMove;
        forbiddenMoves.push_back(Move(-lastMoveY, -lastMoveX));
        // must turn
        if (count >= 3) {
            forbiddenMoves.push_back(lastMove);
        }

        auto addToPos = std::bind(operator+, pos, std::placeholders::_1);
        auto checkValidPos = std::bind(isValidPos, map, std::placeholders::_1);
        auto nextPositions = possible_moves
            | std::views::filter([&forbiddenMoves](const Pos& p)
                { return std::find(forbiddenMoves.begin(), forbiddenMoves.end(), p) == forbiddenMoves.end(); })
            | std::views::transform(addToPos)
            | std::views::filter(checkValidPos);

        for (auto next : nextPositions) {
            // std::cout << "next " << next << std::endl;
            const auto [row, col] = next;
            const auto newLoss = loss + map[row][col];
            const auto move = next - pos;

            auto nextMoveAndCount = addMove(lastMoveAndCount, move);

            if (!visited.contains({next, nextMoveAndCount})) {
                if (!moves_loss_map[row][col].contains(nextMoveAndCount) || newLoss < moves_loss_map[row][col][nextMoveAndCount]) {
                    moves_loss_map[row][col][nextMoveAndCount] = newLoss;
                    pq.push(LossAndPos(newLoss, next, nextMoveAndCount));
                }
            }
        }
    }
#if 0
    for (auto kv : moves_loss_map[rows - 1][cols - 1]) {
        auto [lastMoveAndCount, loss] = kv;
        std::cout << lastMoveAndCount << "; " << loss << std::endl;
    }
#endif
    return std::ranges::min(moves_loss_map[rows - 1][cols - 1] | std::views::values);
}

int main() {
    Map2D<int> map;

    auto parseCharToInt = [](char c) -> int { return c - '0'; };
    for (std::string line; std::getline(std::cin, line);) {
        auto transformed = line | std::views::transform(parseCharToInt);
        std::vector<int> ints;
        std::ranges::copy(transformed, std::back_inserter(ints));
        map.push_back(ints);
    }
    // start pos is considered 0
    map[0][0] = 0;

    std::cout << "Min: " << dijkstra_last_3(map) << std::endl;
    return 0;
}
