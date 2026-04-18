CREATE OR REPLACE FUNCTION create_task_full(
  p_title TEXT,
  p_priority INT4,
  p_profile_id UUID,
  p_tag_names TEXT[],
  p_category_name TEXT,
  p_start_time TIMESTAMPTZ default null,
  p_due_time TIMESTAMPTZ default null
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  v_task_id INT8;
  v_tag_name TEXT;
  v_tag_id INT8;
  v_category_id INT8;
BEGIN
  SELECT id INTO v_category_id
  FROM category
  WHERE profile_id = p_profile_id AND name ILIKE p_category_name
  LIMIT 1;

  IF v_category_id IS NULL THEN
     SELECT id INTO v_category_id FROM category WHERE profile_id = p_profile_id AND name = 'Cá nhân' LIMIT 1;
  END IF;

  INSERT INTO task (title, priority, profile_id, status, category_id,start_time,due_time)
  VALUES (p_title, p_priority, p_profile_id, 0,v_category_id,p_start_time,p_due_time)
  RETURNING id INTO v_task_id;

  IF p_tag_names IS NOT NULL THEN
    FOREACH v_tag_name IN ARRAY p_tag_names
    LOOP
      v_tag_name := trim(v_tag_name);

      IF v_tag_name != '' THEN
        INSERT INTO tag (name, profile_id, color_code)
        VALUES (v_tag_name, p_profile_id, '#6200EE')
        ON CONFLICT (name, profile_id)
        DO UPDATE SET name = EXCLUDED.name
        RETURNING id INTO v_tag_id;


        INSERT INTO task_tags (task_id, tag_id)
        VALUES (v_task_id, v_tag_id)
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  RETURN json_build_object(
    'success', true,
    'task_id', v_task_id,
    'message', 'Đã tạo task với priority ' || p_priority
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;