CREATE OR REPLACE FUNCTION get_user_profile_stats(p_days INT DEFAULT 90)
RETURNS JSON
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_user_id UUID;
    v_username TEXT;
    v_avatar TEXT;
    v_tasks_done INT;
    v_current_streak INT;
    v_heatmap_data JSON;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    SELECT username, avatar INTO v_username, v_avatar
    FROM public.profile
    WHERE id = v_user_id;

    SELECT COUNT(*) INTO v_tasks_done
    FROM public.task
    WHERE profile_id = v_user_id AND status = 1;

    -- Get task done per day for heatmap
    SELECT json_object_agg(task_date::TEXT, task_count) INTO v_heatmap_data
    FROM (
        SELECT DATE(updated_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS task_date, COUNT(*) AS task_count
        FROM public.task
        WHERE profile_id = v_user_id AND status = 1
          AND updated_at >= ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::DATE - (p_days || ' days')::INTERVAL)
        GROUP BY DATE(updated_at AT TIME ZONE 'Asia/Ho_Chi_Minh')
    ) t;

    WITH completed_dates AS (
        SELECT DISTINCT DATE(updated_at AT TIME ZONE 'Asia/Ho_Chi_Minh') AS task_date
        FROM public.task
        WHERE profile_id = v_user_id AND status = 1
    ),
    streak_groups AS (
        SELECT task_date,
               task_date - (ROW_NUMBER() OVER (ORDER BY task_date))::INT AS grp
        FROM completed_dates
    ),
    streak_counts AS (
        SELECT grp, MAX(task_date) as end_date, COUNT(*) as streak_length
        FROM streak_groups
        GROUP BY grp
    )
    SELECT COALESCE(MAX(streak_length), 0) INTO v_current_streak
    FROM streak_counts
    WHERE end_date >= ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::DATE - INTERVAL '1 day');


    RETURN json_build_object(
        'name', COALESCE(v_username, 'Unknown User'),
        'avatarUrl', COALESCE(v_avatar, ''),
        'tasksDone', COALESCE(v_tasks_done, 0),
        'streaks', COALESCE(v_current_streak, 0),
        'heatmapData', COALESCE(v_heatmap_data, '{}'::JSON)
    );
END;
$$;