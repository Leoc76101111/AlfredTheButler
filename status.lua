function task.Execute()
    local local_player = get_local_player()
    if not local_player then
        return
    end

    local restock_trigger = false
    local status = all_task_done()
    if status.complete then
        utils.reset_all_task()
        task.teleport_trigger_time = nil
        tracker.manual_trigger = false
        tracker.trigger_tasks = false
        tracker.all_task_done = true
        if settings.allow_external and tracker.external_trigger then
            tracker.external_trigger = false
            tracker.external_caller = nil
            if tracker.external_trigger_callback then
                pcall(tracker.external_trigger_callback)
                tracker.external_trigger_callback = nil
            end
        end
    end

    if tracker.restock_count > 0 then
        restock_trigger = true
    end

    if tracker.timeout then
        task.status = status_enum['TIMEOUT']
    elseif ((settings.allow_external and tracker.external_trigger) or
        tracker.inventory_full or tracker.manual_trigger) or restock_trigger
    then
        if settings.get_export_keybind_state() and task.status ~= status_enum['WAITING'] then
            utils.export_inventory_info()
        end
        
        -- Add teleport trigger for manual activation
        if tracker.manual_trigger then
            tracker.teleport = true
        end
        
        -- Check and set task flags based on settings/parameters
        if settings.stash_all_socketables and #get_local_player():get_socketable_items() > 0 then
            tracker.stash_socketables = true
        end
        if settings.stash_extra_materials then
            if #get_local_player():get_consumable_items() > 0 then
                tracker.stash_boss_materials = true
            end
            if #get_local_player():get_dungeon_key_items() > 0 then
                tracker.stash_compasses = true
            end
        end
        
        -- Set repair flag if enabled in settings
        if settings.auto_repair then
            tracker.repair_count = 1  -- This will trigger repair task
        end
        
        -- Set sell/salvage flags if enabled
        if settings.auto_sell then
            tracker.sell_count = 1    -- This will trigger sell task
        end
        if settings.auto_salvage then
            tracker.salvage_count = 1 -- This will trigger salvage task
        end

        tracker.trigger_tasks = true
        task.status = status_enum['WAITING']
    else
        task.status = status_enum['IDLE']
        tracker.last_task = task.name
    end
end 