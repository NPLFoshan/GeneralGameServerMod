local mapdata = {
    {19200, 5, 19200, 52},
    {19201, 5, 19200, 52},
    {19206, 5, 19200, 52},
    {19207, 5, 19200, 52},
    {19212, 5, 19200, 52},
    {19213, 5, 19200, 52},
    {19218, 5, 19200, 52},
    {19219, 5, 19200, 52}
}

local checkpoints = {{19200, 5, 19200}, {19207, 5, 19200}, {19213, 5, 19200}, {19219, 5, 19200}}

local aabb = {min = {0xffffffff, 0xffffffff, 0xffffffff}, max = {0, 0, 0}}

function main()
    for k, v in ipairs(mapdata) do
        local x, y, z = v[1], v[2], v[3]
        SetBlock(x, y, z, v[4])

        aabb.min[1] = math.min(aabb.min[1], x - 2)
        aabb.min[2] = math.min(aabb.min[2], y - 2)
        aabb.min[3] = math.min(aabb.min[3], z - 2)

        aabb.max[1] = math.max(aabb.max[1], x + 2)
        aabb.max[2] = math.max(aabb.max[2], y + 2)
        aabb.max[3] = math.max(aabb.max[3], z + 2)
    end
end

local myid = GetPlayerEntityId()
local last_checkpoint = 1
local stop = false
function loop()
    if stop then
        return
    end
    local x, y, z = GetEntityBlockPos(myid)
    local lcp = checkpoints[last_checkpoint]
    if x < aabb.min[1] or x > aabb.max[1] or y < aabb.min[2] or y > aabb.max[2] or z < aabb.min[3] or z > aabb.max[3] then
        SetEntityBlockPos(myid, lcp[1], lcp[2] + 1, lcp[3])
        print(lcp[1], lcp[2] + 1, lcp[3], x, y, z)
        return
    end

    for i = last_checkpoint + 1, #checkpoints do
        local cp = checkpoints[i]
        if cp[1] == x and cp[2] == (y - 1) and cp[3] == z then
            last_checkpoint = i
            if last_checkpoint == #checkpoints then
                Tip("到达终点！")
                SetBlock(cp[1], cp[2], cp[3], 171)
                stop = true
            else
                SetBlock(cp[1], cp[2], cp[3], 51)
            end
            break
        end
    end
end