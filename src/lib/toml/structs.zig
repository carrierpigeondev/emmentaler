pub const ItemTable = struct {
    items: []Item,
};

pub const Item = struct {
    uiid: []const u8, // unique item identifier
};
