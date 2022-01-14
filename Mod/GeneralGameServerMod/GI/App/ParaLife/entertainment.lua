
print("========entertainment==========");

entertainment = module();

entertainment.delivery_direction = 1;
entertainment.delivery_step = 0.01;
entertainment.delivery_speed = 1;
entertainment.delivery_stop = false;

function delivery_tuopan()
    local tuopan_list = {};
    local function add_tuopan_entity(bx, by, bz)
        local entities = GetEntitiesInBlock(bx, by, bz);
        if (not entities) then return end 
        for entity in pairs(entities) do
            local asset = entity:GetMainAssetPath();
            local filename = string.match(asset or "", "([^\\/]*)$");
            if (filename == "tuopan.bmax" and entity.class_name == "LiveModel") then
                entity:SetCanDrag(false);
                local x, y, z = entity:GetPosition();
                local bx, by, bz = entity:GetBlockPos();
                local facing = entity:GetFacing();
                table.insert(tuopan_list, {
                    entity = entity,
                    bx = bx, by = by, bz = bz,
                    x = x, y = y, z = z,
                    facing = facing,
                });
                -- print(bx, by, bz)
                return ;
            end
        end
    end

    local points = {
        {19210,6,19256},
        {19222,6,19256},
        {19222,6,19273},
        {19210,6,19273},
    }

    local size = (#points) - 1;
    local pos = points[1];
    local dx, dy, dz = 0, 0, 0;

    for i = 1, size do 
        dx, dy, dz = points[i + 1][1] - points[i][1], points[i + 1][2] - points[i][2], points[i + 1][3] - points[i][3];
        local max_dist = math.max(math.abs(dx), math.max(dz));
        dx, dy, dz = dx > 0 and 1 or (dx < 0 and -1 or 0), dy > 0 and 1 or (dy < 0 and -1 or 0),  dz > 0 and 1 or (dz < 0 and -1 or 0);
        for j = 1, max_dist do
            add_tuopan_entity(pos[1], pos[2], pos[3]);
            pos[1], pos[2], pos[3] = pos[1] + dx, pos[2] + dy, pos[3] + dz;
        end
    end
    add_tuopan_entity(pos[1], pos[2], pos[3]);

    async_run(function()
        while(true) do
            if (not entertainment.delivery_stop) then
                local size = #tuopan_list;
                local total_step_count = math.floor(__BlockSize__ / entertainment.delivery_step);
                local step_count = total_step_count;
                local delivery_direction = entertainment.delivery_direction;
                local delivery_step = entertainment.delivery_step;
                local delivery_speed = entertainment.delivery_speed;
                local is_move = true;
                while (step_count > 0) do
                    local step_delivery_direction = entertainment.delivery_direction;
                    if (is_move and delivery_direction ~= step_delivery_direction) then
                        step_count = total_step_count - step_count;
                        is_move = false;
                    end
                    if (not is_move and delivery_direction == step_delivery_direction) then
                        step_count = total_step_count - step_count;
                        is_move = true;
                    end
                    local index = 1;
                    local dx, dy, dz = 0, 0, 0;
                    for i = 1, size do
                        local next_index = index + step_delivery_direction;
                        next_index = next_index > size and 1 or (next_index < 1 and size or next_index);
                        local tuopan = tuopan_list[index];
                        local next_tuopan = tuopan_list[next_index];
                        if (delivery_direction > 0 and index == size) then
                            dx, dy, dz = tuopan_list[index].bx - tuopan_list[index - 1].bx, tuopan_list[index].by - tuopan_list[index - 1].by, tuopan_list[index].bz - tuopan_list[index - 1].bz;
                        elseif (delivery_direction < 0 and index == 1) then 
                            dx, dy, dz = tuopan_list[index].bx - tuopan_list[index + 1].bx, tuopan_list[index].by - tuopan_list[index + 1].by, tuopan_list[index].bz - tuopan_list[index + 1].bz;
                        else 
                            dx, dy, dz = tuopan_list[index + delivery_direction].bx - tuopan_list[index].bx, tuopan_list[index + delivery_direction].by - tuopan_list[index].by, tuopan_list[index + delivery_direction].bz - tuopan_list[index].bz;
                        end
                        local x, y, z = tuopan.entity:GetPosition();
                        if (step_delivery_direction == delivery_direction) then
                            tuopan.entity:SetPosition(x + dx * delivery_step, y + dy * delivery_step, z + dz * delivery_step);
                        else
                            tuopan.entity:SetPosition(x - dx * delivery_step, y - dy * delivery_step, z - dz * delivery_step);
                        end
                        index = next_index;
                    end
                    step_count = step_count - 1;
                    sleep(math.floor(50 / entertainment.delivery_speed));
                end

                if (is_move) then
                    local index = 1;
                    local first_entity = tuopan_list[index].entity;
                    for i = 1, size do
                        local next_index = index - delivery_direction;
                        next_index = next_index > size and 1 or (next_index < 1 and size or next_index);
                        local tuopan = tuopan_list[index];
                        local next_tuopan = tuopan_list[next_index];
                        if (next_index == 1) then 
                            tuopan.entity = first_entity;
                        else
                            tuopan.entity = next_tuopan.entity;
                        end 
                        tuopan.entity:SetPosition(tuopan.x, tuopan.y, tuopan.z);
                        tuopan.entity:SetFacing(tuopan.facing);
                        index = next_index;
                    end
                end
            else
                sleep(100);
            end
        end
    end);
end

delivery_tuopan();

RegisterCodeBlockBroadcastEvent("delivery_stop", function(msg)
    entertainment.delivery_stop = not entertainment.delivery_stop;
end);

RegisterCodeBlockBroadcastEvent("delivery_direction_left", function(msg)
    if (entertainment.delivery_direction < 0) then
        entertainment.delivery_direction = 1;
        entertainment.delivery_speed = 1;
    else
        entertainment.delivery_speed = math.min(entertainment.delivery_speed * 2, 8);
    end
end);

RegisterCodeBlockBroadcastEvent("delivery_direction_right", function(msg)
    if (entertainment.delivery_direction > 0) then
        entertainment.delivery_direction = -1;
        entertainment.delivery_speed = 1;
    else
        entertainment.delivery_speed = math.min(entertainment.delivery_speed * 2, 8);
    end
end);

function clear()
    for _, tuopan in ipairs(tuopan_list) do
        tuopan.entity:SetPosition(tuopan.x, tuopan.y, tuopan.z);
    end
end