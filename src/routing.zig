const std = @import("std");
const lattice_mod = @import("lattice.zig");

pub const MAX_TOKENS: usize = 64;
pub const MAX_ARBITRATION_REQUESTS: usize = 1024;
pub const ELIGIBLE_SITE_COUNT: usize = 420;
pub const MAX_GRAPH_EDGES: usize = ELIGIBLE_SITE_COUNT * (ELIGIBLE_SITE_COUNT - 1) / 2;

pub const Policy = enum(u8) {
    axial_one_step,
    supplied_edge_graph,
};

pub const Edge = struct {
    a: u16,
    b: u16,
};

pub const Token = struct {
    id: u16,
    position: lattice_mod.Coord,
};

pub const MoveRequest = struct {
    token: Token,
    target: lattice_mod.Coord,
};

pub const ArbitrationOutcome = struct {
    token_id: u16,
    result: MoveResult,
};

pub const MoveResult = enum {
    moved,
    invalid_source,
    primary_origin_forbidden,
    invalid_target,
    non_axis_move,
    non_adjacent_move,
    non_fano_channel,
    occupied,
    arbitration_lost,
};

pub const RouterError = error{
    TooManyTokens,
    DuplicateTokenId,
    InvalidStartingPosition,
    PrimaryOriginForbidden,
    DuplicateStartingPosition,
    InvalidEdgeGraph,
};

pub const Router = struct {
    lattice: lattice_mod.Lattice,
    policy: Policy = .axial_one_step,
    edges: [MAX_GRAPH_EDGES]Edge = undefined,
    edge_count: usize = 0,
    tokens: [MAX_TOKENS]Token = undefined,
    token_count: usize = 0,
    locks: [lattice_mod.NODE_COUNT]bool = [_]bool{false} ** lattice_mod.NODE_COUNT,
    occupied: [lattice_mod.NODE_COUNT]bool = [_]bool{false} ** lattice_mod.NODE_COUNT,

    pub fn init(lattice: lattice_mod.Lattice) Router {
        return .{ .lattice = lattice };
    }

    pub fn initWithGraph(lattice: lattice_mod.Lattice, edges: []const Edge) RouterError!Router {
        if (!validGraph(&lattice, edges)) return error.InvalidEdgeGraph;
        var router = init(lattice);
        router.policy = .supplied_edge_graph;
        router.edge_count = edges.len;
        @memcpy(router.edges[0..edges.len], edges);
        return router;
    }

    pub fn hasChannel(self: *const Router, source: lattice_mod.Coord, target: lattice_mod.Coord) bool {
        if (self.policy == .axial_one_step) return isOneStepChannel(&self.lattice, source, target);
        const source_index = lattice_mod.Lattice.index(source) orelse return false;
        const target_index = lattice_mod.Lattice.index(target) orelse return false;
        if (!isEligible(&self.lattice, source) or !isEligible(&self.lattice, target)) return false;
        return graphContains(self.edges[0..self.edge_count], @intCast(source_index), @intCast(target_index));
    }

    pub fn addToken(self: *Router, token: Token) RouterError!void {
        if (self.token_count == MAX_TOKENS) return error.TooManyTokens;
        if (isPrimary(token.position)) return error.PrimaryOriginForbidden;
        if (!isEligible(&self.lattice, token.position)) return error.InvalidStartingPosition;
        for (self.tokens[0..self.token_count]) |existing| {
            if (existing.id == token.id) return error.DuplicateTokenId;
            if (coordEqual(existing.position, token.position)) return error.DuplicateStartingPosition;
        }
        self.tokens[self.token_count] = token;
        self.occupied[lattice_mod.Lattice.index(token.position).?] = true;
        self.token_count += 1;
    }

    pub fn currentToken(self: *const Router, id: u16) ?Token {
        for (self.tokens[0..self.token_count]) |token| {
            if (token.id == id) return token;
        }
        return null;
    }

    pub fn isOccupied(self: *const Router, position: lattice_mod.Coord) bool {
        const index = lattice_mod.Lattice.index(position) orelse return false;
        return self.occupied[index];
    }

    pub fn isLocked(self: *const Router, position: lattice_mod.Coord) bool {
        const index = lattice_mod.Lattice.index(position) orelse return false;
        return self.locks[index];
    }

    pub fn move(self: *Router, id: u16, target: lattice_mod.Coord) MoveResult {
        const token_index = self.findTokenIndex(id) orelse return .invalid_source;
        const source = self.tokens[token_index].position;
        if (isPrimary(source)) return .primary_origin_forbidden;
        if (isPrimary(target)) return .primary_origin_forbidden;
        if (!isEligible(&self.lattice, source)) return .invalid_source;
        if (self.policy == .supplied_edge_graph) {
            if (!isInBounds(target)) return .invalid_target;
            if (!isEligible(&self.lattice, target)) return .invalid_target;
            if (self.isOccupied(target)) return .occupied;
            if (!self.hasChannel(source, target)) return .non_fano_channel;
            return self.commitMove(token_index, source, target);
        }
        if (self.policy == .axial_one_step) {
            const geometry = validateGeometry(source, target);
            if (geometry != .moved) return geometry;
        }
        if (!isEligible(&self.lattice, target)) return .invalid_target;
        if (self.isOccupied(target)) return .occupied;
        if (!self.hasChannel(source, target)) return .non_fano_channel;
        return self.commitMove(token_index, source, target);
    }

    fn commitMove(self: *Router, token_index: usize, source: lattice_mod.Coord, target: lattice_mod.Coord) MoveResult {
        const source_index = lattice_mod.Lattice.index(source).?;
        const target_index = lattice_mod.Lattice.index(target).?;
        self.locks[source_index] = true;
        self.locks[target_index] = true;
        defer {
            self.locks[source_index] = false;
            self.locks[target_index] = false;
        }
        self.occupied[source_index] = false;
        self.occupied[target_index] = true;
        self.tokens[token_index].position = target;
        return .moved;
    }

    pub fn arbitrate(self: *Router, requests: []const MoveRequest, outcomes: []ArbitrationOutcome) error{OutputTooSmall}!usize {
        if (outcomes.len < requests.len) return error.OutputTooSmall;
        if (requests.len > MAX_ARBITRATION_REQUESTS) return error.OutputTooSmall;
        var winner_for_target: [MAX_ARBITRATION_REQUESTS]usize = undefined;
        @memset(winner_for_target[0..requests.len], std.math.maxInt(usize));
        for (requests, 0..) |request, i| {
            outcomes[i] = .{ .token_id = request.token.id, .result = .invalid_source };
            var duplicate_request_id = false;
            for (requests[0..i]) |previous| {
                if (previous.token.id == request.token.id) duplicate_request_id = true;
            }
            if (duplicate_request_id) continue;
            const existing = self.currentToken(request.token.id) orelse continue;
            if (!coordEqual(existing.position, request.token.position)) continue;
            outcomes[i].result = validateMove(self, request.token.id, request.target);
        }
        for (requests, 0..) |request, i| {
            if (outcomes[i].result != .moved) continue;
            var winner = i;
            for (requests, 0..) |other, j| {
                if (outcomes[j].result != .moved or !coordEqual(request.target, other.target)) continue;
                if (compareRequest(other, requests[winner]) == .lt) winner = j;
            }
            winner_for_target[i] = winner;
        }

        for (requests, 0..) |_, i| {
            if (outcomes[i].result != .moved) continue;
            if (winner_for_target[i] != i) outcomes[i].result = .arbitration_lost;
        }

        var order: [MAX_ARBITRATION_REQUESTS]usize = undefined;
        var winner_count: usize = 0;
        for (requests, 0..) |_, i| {
            if (outcomes[i].result == .moved) {
                order[winner_count] = i;
                winner_count += 1;
            }
        }
        std.mem.sort(usize, order[0..winner_count], requests, struct {
            fn lessThan(reqs: []const MoveRequest, a: usize, b: usize) bool {
                return compareRequest(reqs[a], reqs[b]) == .lt;
            }
        }.lessThan);
        var applied: usize = 0;
        for (order[0..winner_count]) |outcome_index| {
            const request = requests[outcome_index];
            const token_index = self.findTokenIndex(request.token.id) orelse {
                outcomes[outcome_index].result = .invalid_source;
                continue;
            };
            const source = self.tokens[token_index].position;
            if (self.isOccupied(request.target)) {
                outcomes[outcome_index].result = .occupied;
                continue;
            }
            outcomes[outcome_index].result = self.commitMove(token_index, source, request.target);
            if (outcomes[outcome_index].result == .moved) applied += 1;
        }
        return applied;
    }

    pub fn validate(self: *const Router) bool {
        if (self.token_count > MAX_TOKENS) return false;
        if (self.edge_count > MAX_GRAPH_EDGES) return false;
        if (self.policy == .axial_one_step and self.edge_count != 0) return false;
        if (self.policy == .supplied_edge_graph and !validGraph(&self.lattice, self.edges[0..self.edge_count])) return false;
        var expected_occupied = [_]bool{false} ** lattice_mod.NODE_COUNT;
        for (self.tokens[0..self.token_count], 0..) |token, i| {
            if (isPrimary(token.position) or !isEligible(&self.lattice, token.position)) return false;
            for (self.tokens[0..i]) |previous| {
                if (token.id == previous.id or coordEqual(token.position, previous.position)) return false;
            }
            expected_occupied[lattice_mod.Lattice.index(token.position).?] = true;
        }
        if (!std.mem.eql(bool, &expected_occupied, &self.occupied)) return false;
        for (self.locks) |locked| if (locked) return false;
        return true;
    }

    fn findTokenIndex(self: *const Router, id: u16) ?usize {
        for (self.tokens[0..self.token_count], 0..) |token, i| {
            if (token.id == id) return i;
        }
        return null;
    }
};

fn validateGeometry(source: lattice_mod.Coord, target: lattice_mod.Coord) MoveResult {
    const dx = @as(i16, target.x) - source.x;
    const dy = @as(i16, target.y) - source.y;
    const dz = @as(i16, target.z) - source.z;
    const nonzero_axes: u2 = @as(u2, @intFromBool(dx != 0)) + @as(u2, @intFromBool(dy != 0)) + @as(u2, @intFromBool(dz != 0));
    if (nonzero_axes > 1) return .non_axis_move;
    if (nonzero_axes == 0) return .non_adjacent_move;
    if (@abs(dx) + @abs(dy) + @abs(dz) != 1) return .non_adjacent_move;
    return .moved;
}

fn validateMove(self: *const Router, id: u16, target: lattice_mod.Coord) MoveResult {
    const token = self.currentToken(id) orelse return .invalid_source;
    if (isPrimary(token.position) or isPrimary(target)) return .primary_origin_forbidden;
    if (!isEligible(&self.lattice, token.position)) return .invalid_source;
    if (self.policy == .supplied_edge_graph) {
        if (!isInBounds(target) or !isEligible(&self.lattice, target)) return .invalid_target;
        if (self.isOccupied(target)) return .occupied;
        return if (self.hasChannel(token.position, target)) .moved else .non_fano_channel;
    }
    const geometry = validateGeometry(token.position, target);
    if (geometry != .moved) return geometry;
    if (!isEligible(&self.lattice, target)) return .invalid_target;
    if (self.isOccupied(target)) return .occupied;
    return if (self.hasChannel(token.position, target)) .moved else .non_fano_channel;
}

pub fn eligibleCount(lattice: *const lattice_mod.Lattice) usize {
    var count: usize = 0;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const position = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (!isPrimary(position) and lattice.labelAt(position).? == 0) count += 1;
    }
    return count;
}

pub fn isEligible(lattice: *const lattice_mod.Lattice, position: lattice_mod.Coord) bool {
    if (isPrimary(position)) return false;
    return lattice.labelAt(position) == 0;
}

pub fn isOneStepChannel(lattice: *const lattice_mod.Lattice, source: lattice_mod.Coord, target: lattice_mod.Coord) bool {
    if (!isEligible(lattice, source) or !isEligible(lattice, target)) return false;
    const dx = @as(i16, target.x) - source.x;
    const dy = @as(i16, target.y) - source.y;
    const dz = @as(i16, target.z) - source.z;
    return @abs(dx) + @abs(dy) + @abs(dz) == 1;
}

fn validGraph(lattice: *const lattice_mod.Lattice, edges: []const Edge) bool {
    if (edges.len > MAX_GRAPH_EDGES) return false;
    for (edges, 0..) |edge, i| {
        if (edge.a >= edge.b or edge.b >= lattice_mod.NODE_COUNT) return false;
        const a = lattice_mod.Lattice.coordFromIndex(edge.a) orelse return false;
        const b = lattice_mod.Lattice.coordFromIndex(edge.b) orelse return false;
        if (!isEligible(lattice, a) or !isEligible(lattice, b)) return false;
        if (i > 0 and (edges[i - 1].a > edge.a or (edges[i - 1].a == edge.a and edges[i - 1].b >= edge.b))) return false;
    }
    return true;
}

fn graphContains(edges: []const Edge, a: u16, b: u16) bool {
    const lower = @min(a, b);
    const upper = @max(a, b);
    for (edges) |edge| {
        if (edge.a == lower and edge.b == upper) return true;
    }
    return false;
}

fn isInBounds(position: lattice_mod.Coord) bool {
    return lattice_mod.Lattice.index(position) != null;
}

pub fn isPrimary(position: lattice_mod.Coord) bool {
    return position.x == 0 and position.y == 0 and position.z == 0;
}

fn coordEqual(a: lattice_mod.Coord, b: lattice_mod.Coord) bool {
    return a.x == b.x and a.y == b.y and a.z == b.z;
}

fn manhattan(a: lattice_mod.Coord, b: lattice_mod.Coord) u32 {
    return @intCast(@abs(@as(i16, a.x) - b.x) + @abs(@as(i16, a.y) - b.y) + @abs(@as(i16, a.z) - b.z));
}

pub fn compareRequest(a: MoveRequest, b: MoveRequest) std.math.Order {
    const distance_a = manhattan(a.token.position, a.target);
    const distance_b = manhattan(b.token.position, b.target);
    if (distance_a != distance_b) return std.math.order(distance_a, distance_b);
    if (a.token.position.x != b.token.position.x) return std.math.order(a.token.position.x, b.token.position.x);
    if (a.token.position.y != b.token.position.y) return std.math.order(a.token.position.y, b.token.position.y);
    if (a.token.position.z != b.token.position.z) return std.math.order(a.token.position.z, b.token.position.z);
    return std.math.order(a.token.id, b.token.id);
}

pub fn sortRequests(requests: []MoveRequest) void {
    std.mem.sort(MoveRequest, requests, {}, struct {
        fn lessThan(_: void, a: MoveRequest, b: MoveRequest) bool {
            return compareRequest(a, b) == .lt;
        }
    }.lessThan);
}

pub fn selectArbitrationWinners(requests: []const MoveRequest, winners: []bool) error{OutputTooSmall}!void {
    if (winners.len < requests.len) return error.OutputTooSmall;
    @memset(winners[0..requests.len], false);
    for (requests, 0..) |request, i| {
        var first_for_target = true;
        for (requests[0..i]) |previous| {
            if (coordEqual(request.target, previous.target)) {
                first_for_target = false;
                break;
            }
        }
        if (!first_for_target) continue;
        var best = i;
        for (requests[i + 1 ..], i + 1..) |other, j| {
            if (coordEqual(request.target, other.target) and compareRequest(other, requests[best]) == .lt) best = j;
        }
        winners[best] = true;
    }
}

test "routing eligibility is exactly the 420 non-origin e0 labels" {
    const lattice = lattice_mod.Lattice.init();
    try std.testing.expectEqual(ELIGIBLE_SITE_COUNT, eligibleCount(&lattice));
    try std.testing.expect(!isEligible(&lattice, .{ .x = 0, .y = 0, .z = 0 }));
    var observed: usize = 0;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const position = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (isEligible(&lattice, position)) {
            try std.testing.expectEqual(@as(u3, 0), lattice.labelAt(position).?);
            observed += 1;
        }
    }
    try std.testing.expectEqual(ELIGIBLE_SITE_COUNT, observed);
    var axial_edges: usize = 0;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const position = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (!isEligible(&lattice, position)) continue;
        const candidates = [_]lattice_mod.Coord{
            .{ .x = position.x + 1, .y = position.y, .z = position.z },
            .{ .x = position.x - 1, .y = position.y, .z = position.z },
            .{ .x = position.x, .y = position.y + 1, .z = position.z },
            .{ .x = position.x, .y = position.y - 1, .z = position.z },
            .{ .x = position.x, .y = position.y, .z = position.z + 1 },
            .{ .x = position.x, .y = position.y, .z = position.z - 1 },
        };
        for (candidates) |candidate| if (isEligible(&lattice, candidate)) {
            axial_edges += 1;
        };
    }
    try std.testing.expectEqual(@as(usize, 0), axial_edges);
}

test "caller-supplied graph is canonical, eligible-only, and enables declared edge" {
    const lattice = lattice_mod.Lattice.init();
    const a = firstEligible(&lattice);
    const b = anotherEligible(&lattice, a);
    const ai: u16 = @intCast(lattice_mod.Lattice.index(a).?);
    const bi: u16 = @intCast(lattice_mod.Lattice.index(b).?);
    const edge = Edge{ .a = @min(ai, bi), .b = @max(ai, bi) };
    var router = try Router.initWithGraph(lattice, &.{edge});
    try router.addToken(.{ .id = 1, .position = a });
    try std.testing.expect(router.hasChannel(a, b));
    try std.testing.expectEqual(MoveResult.moved, router.move(1, b));
    try std.testing.expect(router.validate());
    try std.testing.expectError(error.InvalidEdgeGraph, Router.initWithGraph(lattice, &.{.{ .a = edge.b, .b = edge.a }}));
}

test "BLUE defect-line candidate does not guarantee an eligible-site route" {
    const lattice = lattice_mod.Lattice.init();
    const destination = anotherEligible(&lattice, firstEligible(&lattice));
    var failed_sources: usize = 0;
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const source = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (!isEligible(&lattice, source) or coordEqual(source, destination)) continue;
        var current = source;
        var hops: usize = 0;
        while (!coordEqual(current, destination) and hops < lattice_mod.NODE_COUNT) : (hops += 1) {
            const next = blueCandidateNextHop(current, destination) orelse break;
            if (!isEligible(&lattice, next) or manhattan(next, destination) >= manhattan(current, destination)) {
                break;
            }
            current = next;
        }
        if (!coordEqual(current, destination)) failed_sources += 1;
    }
    try std.testing.expect(failed_sources > 0);
}

test "BLUE Fano routing candidate reproduces its documented 24-hop coordinate route" {
    var current = lattice_mod.Coord{ .x = -6, .y = -5, .z = -4 };
    const destination = lattice_mod.Coord{ .x = 2, .y = 3, .z = 4 };
    var hops: usize = 0;
    while (!coordEqual(current, destination) and hops < 42) : (hops += 1) {
        const next = blueCandidateNextHop(current, destination) orelse break;
        try std.testing.expect(manhattan(next, destination) < manhattan(current, destination));
        current = next;
    }
    try std.testing.expect(coordEqual(current, destination));
    try std.testing.expectEqual(@as(usize, 24), hops);
}

test "router rejects primary origin and duplicate occupancy" {
    const lattice = lattice_mod.Lattice.init();
    var router = Router.init(lattice);
    try std.testing.expectError(error.PrimaryOriginForbidden, router.addToken(.{ .id = 1, .position = .{ .x = 0, .y = 0, .z = 0 } }));
    const position = firstEligible(&lattice);
    try router.addToken(.{ .id = 1, .position = position });
    try std.testing.expectError(error.DuplicateStartingPosition, router.addToken(.{ .id = 2, .position = position }));
    try std.testing.expectError(error.DuplicateTokenId, router.addToken(.{ .id = 1, .position = anotherEligible(&lattice, position) }));
    try std.testing.expect(router.validate());
}

test "router rejects unsupported transitions without mutating state" {
    const lattice = lattice_mod.Lattice.init();
    const source = firstEligible(&lattice);
    var router = Router.init(lattice);
    try router.addToken(.{ .id = 5, .position = source });
    const original = router.currentToken(5).?.position;
    const diagonal_result = router.move(5, .{ .x = source.x + 1, .y = source.y + 1, .z = source.z });
    try std.testing.expect(diagonal_result == .non_axis_move or diagonal_result == .invalid_target);
    try std.testing.expectEqual(original, router.currentToken(5).?.position);
    try std.testing.expectEqual(MoveResult.non_adjacent_move, router.move(5, .{ .x = source.x + 2, .y = source.y, .z = source.z }));
    try std.testing.expectEqual(original, router.currentToken(5).?.position);
    try std.testing.expect(router.move(5, .{ .x = source.x + 1, .y = source.y, .z = source.z }) != .moved);
    try std.testing.expectEqual(original, router.currentToken(5).?.position);
    try std.testing.expect(!router.isLocked(source));
    try std.testing.expect(router.validate());
}

test "rejected move preserves reservation and clears transient locks" {
    const lattice = lattice_mod.Lattice.init();
    var router = Router.init(lattice);
    const source = firstEligible(&lattice);
    try router.addToken(.{ .id = 44, .position = source });
    const unsupported = router.move(44, .{ .x = source.x + 1, .y = source.y, .z = source.z });
    try std.testing.expect(unsupported == .invalid_target or unsupported == .non_fano_channel);
    try std.testing.expectEqual(source, router.currentToken(44).?.position);
    try std.testing.expect(router.isOccupied(source));
    try std.testing.expect(!router.isLocked(source));
    try std.testing.expect(router.validate());
}

test "simultaneous arbitration uses distance then coordinate then token ID" {
    const target = lattice_mod.Coord{ .x = -2, .y = -1, .z = 0 };
    const contenders = [_]MoveRequest{
        .{ .token = .{ .id = 9, .position = .{ .x = -1, .y = -1, .z = 0 } }, .target = target },
        .{ .token = .{ .id = 3, .position = .{ .x = 1, .y = -1, .z = 0 } }, .target = target },
        .{ .token = .{ .id = 2, .position = .{ .x = -1, .y = -1, .z = 0 } }, .target = target },
    };
    try std.testing.expectEqual(std.math.Order.lt, compareRequest(contenders[0], contenders[1]));
    try std.testing.expectEqual(std.math.Order.lt, compareRequest(contenders[2], contenders[0]));
    var winners: [3]bool = undefined;
    try selectArbitrationWinners(&contenders, &winners);
    try std.testing.expect(!winners[0]);
    try std.testing.expect(!winners[1]);
    try std.testing.expect(winners[2]);
}

test "arbitration selects a deterministic destination winner" {
    const target = lattice_mod.Coord{ .x = -2, .y = -1, .z = 0 };
    const requests = [_]MoveRequest{
        .{ .token = .{ .id = 9, .position = .{ .x = -1, .y = -1, .z = 0 } }, .target = target },
        .{ .token = .{ .id = 3, .position = .{ .x = 1, .y = -1, .z = 0 } }, .target = target },
        .{ .token = .{ .id = 2, .position = .{ .x = -1, .y = -1, .z = 0 } }, .target = target },
    };
    var winners: [3]bool = undefined;
    try selectArbitrationWinners(&requests, &winners);
    try std.testing.expect(!winners[0]);
    try std.testing.expect(!winners[1]);
    try std.testing.expect(winners[2]);
}

test "router batch API preserves rejection and duplicate-ID outcomes" {
    const lattice = lattice_mod.Lattice.init();
    const source = firstEligible(&lattice);
    var router = Router.init(lattice);
    try router.addToken(.{ .id = 10, .position = source });
    const request = MoveRequest{
        .token = router.currentToken(10).?,
        .target = .{ .x = source.x + 1, .y = source.y, .z = source.z },
    };
    const requests = [_]MoveRequest{ request, request };
    var outcomes: [2]ArbitrationOutcome = undefined;
    _ = try router.arbitrate(&requests, &outcomes);
    try std.testing.expect(outcomes[0].result != .moved);
    try std.testing.expectEqual(MoveResult.invalid_source, outcomes[1].result);
    try std.testing.expect(router.validate());
}

test "batch arbitration reports rejected requests and preserves occupancy" {
    const lattice = lattice_mod.Lattice.init();
    const first = firstEligible(&lattice);
    const second = anotherEligible(&lattice, first);
    var router = Router.init(lattice);
    try router.addToken(.{ .id = 8, .position = first });
    try router.addToken(.{ .id = 3, .position = second });
    const requests = [_]MoveRequest{
        .{ .token = router.currentToken(8).?, .target = .{ .x = 7, .y = 7, .z = 7 } },
        .{ .token = router.currentToken(3).?, .target = .{ .x = -7, .y = -7, .z = -7 } },
    };
    var outcomes: [2]ArbitrationOutcome = undefined;
    const moved = try router.arbitrate(&requests, &outcomes);
    try std.testing.expectEqual(@as(usize, 0), moved);
    try std.testing.expect(outcomes[0].result != .moved and outcomes[1].result != .moved);
    try std.testing.expectEqual(first, router.currentToken(8).?.position);
    try std.testing.expectEqual(second, router.currentToken(3).?.position);
    try std.testing.expect(router.validate());
}

fn firstEligible(lattice: *const lattice_mod.Lattice) lattice_mod.Coord {
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const coordinate = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (isEligible(lattice, coordinate)) return coordinate;
    }
    unreachable;
}

fn anotherEligible(lattice: *const lattice_mod.Lattice, excluded: lattice_mod.Coord) lattice_mod.Coord {
    for (0..lattice_mod.NODE_COUNT) |flat| {
        const coordinate = lattice_mod.Lattice.coordFromIndex(flat).?;
        if (isEligible(lattice, coordinate) and !coordEqual(coordinate, excluded)) return coordinate;
    }
    unreachable;
}

fn blueCandidateNextHop(source: lattice_mod.Coord, destination: lattice_mod.Coord) ?lattice_mod.Coord {
    if (coordEqual(source, destination)) return null;
    const distance = @abs(@as(i16, source.x) - 7) + @abs(@as(i16, source.y) - 7) + @abs(@as(i16, source.z) - 7);
    const line_index: usize = @intCast(@mod(distance, 7));
    const lines = [7][3]u8{
        .{ 1, 2, 3 },
        .{ 1, 4, 5 },
        .{ 1, 7, 6 },
        .{ 2, 4, 6 },
        .{ 2, 5, 7 },
        .{ 3, 4, 7 },
        .{ 3, 6, 5 },
    };
    const line = lines[line_index];
    const allowed = [3]u8{ line[0] % 3, line[1] % 3, line[2] % 3 };
    var best: ?lattice_mod.Coord = null;
    var best_distance: u32 = std.math.maxInt(u32);
    for (0..3) |axis| {
        var permitted = false;
        for (allowed) |candidate| {
            if (candidate == axis) permitted = true;
        }
        if (!permitted) continue;
        var next = source;
        const current = switch (axis) {
            0 => source.x,
            1 => source.y,
            else => source.z,
        };
        const target = switch (axis) {
            0 => destination.x,
            1 => destination.y,
            else => destination.z,
        };
        if (current == target) continue;
        const stepped: i8 = if (current < target) current + 1 else current - 1;
        switch (axis) {
            0 => next.x = stepped,
            1 => next.y = stepped,
            else => next.z = stepped,
        }
        const next_distance = manhattan(next, destination);
        if (next_distance < best_distance) {
            best_distance = next_distance;
            best = next;
        }
    }
    return best orelse blk: {
        var fallback = source;
        if (source.x != destination.x) fallback.x += if (source.x < destination.x) 1 else -1 else if (source.y != destination.y) fallback.y += if (source.y < destination.y) 1 else -1 else if (source.z != destination.z) fallback.z += if (source.z < destination.z) 1 else -1;
        break :blk fallback;
    };
}
