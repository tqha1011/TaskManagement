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
    v_daily_counts INT[];
    v_result JSON;

BEGIN
    SELECT COUNT(*), COALESCE(SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END), 0)
    INTO v_today_total, v_today_completed
    FROM task
    WHERE profile_id = p_profile_id AND date(start_time) = CURRENT_DATE;

    IF v_today_total > 0 THEN
        v_today_completed_percent := ((v_today_completed)::FLOAT / (v_today_total)) * 100;
    ELSE
        v_today_completed_percent := 0;
    END IF;

    -- 2. Sum of task done in this week
    SELECT COUNT(*) INTO v_this_week_total
    FROM task
    WHERE profile_id = p_profile_id
    AND status = 1
    AND updated_at >= date_trunc('week', CURRENT_DATE)
    AND updated_at < date_trunc('week', CURRENT_DATE) + INTERVAL '1 week';

    -- 3. Sum of task done last week
    SELECT COUNT(*) INTO v_last_week_total
    FROM task
    WHERE profile_id = p_profile_id
    AND status = 1
    AND updated_at >= date_trunc('week', CURRENT_DATE) - INTERVAL '1 week'
    AND updated_at < date_trunc('week', CURRENT_DATE);

    IF v_last_week_total > 0 THEN
        v_growth := ((v_this_week_total - v_last_week_total)::FLOAT / v_last_week_total) * 100;
    ELSIF v_this_week_total > 0 THEN
        v_growth := 100;
    END IF;

    -- 4. Get array of weekdays
    SELECT ARRAY_AGG(cnt) INTO v_daily_counts
    FROM (
        SELECT COUNT(tk.id) as cnt
        FROM generate_series(
            date_trunc('week', CURRENT_DATE),
            date_trunc('week', CURRENT_DATE) + INTERVAL '6 days',
            INTERVAL '1 day'
        ) AS days(day)
        LEFT JOIN task tk ON date(tk.updated_at) = date(days.day)
            AND tk.profile_id = p_profile_id
            AND tk.status = 1
        GROUP BY days.day
        ORDER BY days.day
    ) t;

    -- 5. Get 4 recent tasks
    SELECT json_agg(row_to_json(t)) INTO v_recent_tasks
    FROM (
        SELECT tk.id, tk.title, tk.updated_at, ct.avatar
        FROM task tk
        LEFT JOIN category ct ON tk.category_id = ct.id
        WHERE tk.profile_id = p_profile_id AND tk.status = 1
        ORDER BY tk.updated_at DESC
        LIMIT 4
    ) t;

    -- 6. Return JSON
    v_result := json_build_object(
        'today', json_build_object('total', v_today_total, 'completed', v_today_completed),
        'today_completed_percentage', ROUND(v_today_completed_percent::NUMERIC, 2),
        'this_week_total', v_this_week_total,
        'growth_percentage', ROUND(v_growth::NUMERIC, 2),
        'daily_counts', v_daily_counts,
        'recent_tasks', COALESCE(v_recent_tasks, '[]'::json)
    );

    RETURN v_result;
END;
$$;