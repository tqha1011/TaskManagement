CREATE OR REPLACE FUNCTION get_user_statistics(p_profile_id UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_today_total INT;
    v_today_completed INT;
    v_today_completed_percent FLOAT := 0;
    v_this_week_total INT;
    v_last_week_total INT;
    v_growth FLOAT := 0;
    v_recent_tasks JSON;
    v_result JSON;

BEGIN
    -- Calculate the tasks completed today / the total task tody
    SELECT COUNT(*), COALESCE(SUM(CASE when status = 1 then 1 else 0 end),0)
    into v_today_total,v_today_completed
    from task
    where profile_id = p_profile_id and date(created_at) = CURRENT_DATE;

    if v_today_total > 0 then
        v_today_completed_percent := ((v_today_completed)::FLOAT/(v_today_total)) * 100;
    else
        v_today_completed_percent := 0;
    end if;

    -- Calculate sum of tasks done from monday to present
    SELECT COUNT(*) into v_this_week_total
    from task
    where profile_id = p_profile_id
    and created_at >= date_trunc('week',CURRENT_DATE)
    and created_at < date_trunc('week',CURRENT_DATE) + INTERVAL '1 week';

    -- Calculate tasks done last week
    SELECT COUNT(*) INTO v_last_week_total
    FROM task
    WHERE profile_id = p_profile_id
    AND created_at >= date_trunc('week', CURRENT_DATE) - INTERVAL '1 week'
    AND created_at < date_trunc('week', CURRENT_DATE);

    if v_last_week_total > 0 then
        v_growth := ((v_this_week_total - v_last_week_total)::FLOAT / v_last_week_total) * 100;
    elseif v_this_week_total > 0 then
        v_growth := 100;
    end if;

    SELECT json_agg(row_to_json(t)) INTO v_recent_tasks
    FROM (
        SELECT tk.id,tk.title,tk.updated_at, ct.avatar
        from task tk
        left join category ct on tk.category_id = ct.id
        where tk.profile_id = p_profile_id and tk.status = 1
        order by tk.updated_at desc
        limit 4
    ) t;

    v_result := json_build_object(
        'today', json_build_object('total', v_today_total, 'completed', v_today_completed),
        'today_completed_percentage', v_today_completed_percent,
        'this_week_total', v_this_week_total,
        'growth_percentage', ROUND(v_growth::NUMERIC,2),
        'recent_tasks', COALESCE(v_recent_tasks, '[]'::json)
    );

    RETURN v_result;
END;
$$;